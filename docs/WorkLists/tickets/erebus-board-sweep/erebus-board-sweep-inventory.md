# Erebus board sweep — inventory of everything touched

Generated from source artifacts: the merge commits on `local-fixes` (`git log --first-parent main..local-fixes`), each merge's file diff, the live board read with `GET /data` on 2026-09-28 (read-only), and the plan's tier tables. Companion to `[erebus-board-sweep-plan.md](./erebus-board-sweep-plan.md)`.

## Why 51 packages is not 51 tickets

- **51 work packages** were merged. A package is one branch, one reviewable merge commit.
- **37 packages came from board cards**, covering **43 distinct cards**. They are not one-to-one: 3 packages each resolved several cards that shared one cause (`refresh-preserves-focus` → 4, `verify-requires-testing` → 3, `logging-levels` → 3), and 1 card was addressed by two packages (`todo-1779921748180-601fd273`).
- **14 packages have no card.** They are defects found during the sweep — by agents while working, by review, or by the two integration QA passes. Each row in section B says what was found.
- **1 other commit** on the branch is not a package: `7b081a8` Align AI reload tests with re-sort-then-reveal order (a test-order alignment made while merging).
- **The board was not modified during the sweep.** After the owner's review (the **Review** column below), the verdicts were applied on 2026-09-28. The "Card status / done" column still shows the state *before* that.
  - **Checked Completed:** 9 cards (rows 1, 4, 5, 12, 17, 20, 21, 27, 39). Their status was left as it was.
  - **Set to In Review:** 17 cards. Rows 29 and 30 were already In Review, which makes 19 in all.
  - **Set to In Progress:** 13 cards.
  - **Rejected by the server:** rows **2** and **15**. The server said `Task status is not available for this card's color tags`: both cards carry only the `UI/UX` tag, and statuses are enabled only for Backend / Bug / Features / Investigation / Task. Both cards were left unchanged; setting them needs a status-enabled tag on the card, which is your call.
  - No card was moved between columns, and no note, checklist or tag was touched. A before/after diff of the whole board showed no other change.



## A. Board cards touched (43)


| #   | Card id                       | Card (first line)                                                                                                                                                                                                                   | Board › Column                        | Card status / done | Package                                             | Review                                                                                                                                                                  |
| --- | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- | ------------------ | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `todo-1782595555320-b0df9186` | Fix search bar right side padding                                                                                                                                                                                                   | Erebus › Code Changes (Search)        | Ready / no         | `search-bar-right-gap`                              | Pass - Mark / Check Completed                                                                                                                                           |
| 2   | `todo-1782760132922-97997fda` | Update settings menu scroll bar styles                                                                                                                                                                                              | Erebus › Code Changes (Settings Menu) | Unrefined / no     | `settings-scrollbar-style`                          | Mark In progress Sub menu items in settings menus still have the a different type of scroll bar, not consistent with the top level, should all be using the same class. |
| 3   | `todo-1779650286782`          | When generating a significant amount of Ai requests, the toast message goes off screen, it should scroll                                                                                                                            | Erebus › Code Changes (Ai)            | Unrefined / no     | `toast-stack-overflow`                              | Move to In Review                                                                                                                                                       |
| 4   | `todo-1778824878134`          | Edit in Tag window for 2nd tag doesn't work                                                                                                                                                                                         | Erebus › Code Changes (Tagging)       | — / no             | `tag-window-second-tag-edit`                        | Pass - Mark / Check Completed                                                                                                                                           |
| 5   | `todo-1781111162493-5a1e671f` | Fix Auto-Scroll for New Column Tasks                                                                                                                                                                                                | Erebus › Code Changes (Columns)       | Ready / no         | `new-task-autoscroll`                               | Pass - Mark / Check Completed                                                                                                                                           |
| 6   | `todo-1787694813073-54eb6118` | Investigate Prompt Injection Multi-Card Generation Bug                                                                                                                                                                              | Erebus › Code Changes (Ai)            | Ready / no         | `ai-multi-card-persist`                             | Move to In Review                                                                                                                                                       |
| 7   | `todo-1778984818921`          | Moving UI shows columns to move into not in alphabetical order.                                                                                                                                                                     | Erebus › Code Changes (Columns)       | — / no             | `move-menu-alpha-order`                             | Was not resolved, menus for both columns and cards, all of the menus are not sorted alphabeticallyMark In Progress                                                     |
| 8   | `todo-1708048105823`          | Implement Database Sync Error Handling Policy                                                                                                                                                                                       | Erebus › Code Changes (Data)          | — / no             | `write-failure-feedback`                            | Move to In Review                                                                                                                                                       |
| 9   | `todo-1779739234482-55b57f70` | Resolve Automatic Sorting Issue for Completed Items                                                                                                                                                                                 | Erebus › Code Changes (Sorting)       | — / no             | `auto-sort-on-change`                               | Move to In Review                                                                                                                                                       |
| 10  | `todo-1779025832029`          | Fix Column Drag-and-Drop Visual Spacing                                                                                                                                                                                             | Erebus › Code Changes (Columns)       | Ready / no         | `dnd-placeholder-line`                              | Partial, mark in progress, the space is a line for items that have overflow, but for columns without overflow there is still a large white space.                       |
| 11  | `todo-1778620266948`          | Investigate Data Loss During Card Moves                                                                                                                                                                                             | Erebus › Code Changes (Data)          | — / no             | `card-move-integrity`                               | Move to In Review                                                                                                                                                       |
| 12  | `todo-1779025915731`          | Fix column deletion visual flash bug                                                                                                                                                                                                | Erebus › Code Changes (Columns)       | Ready / no         | `column-delete-flash`                               | Pass - Mark / Check Completed                                                                                                                                           |
| 13  | `todo-1783610886391-e7583884` | Enable Custom Sorting for Status Workflow Settings                                                                                                                                                                                  | Erebus › Code Changes (Settings Menu) | Ready / no         | `status-reorder-settings`                           | Not certain if any changes actually made a difference, fail, move to in progress There should be the abililty to sort of the settings menu, no such sorting exists.     |
| 14  | `todo-1779570847318`          | Add Cancel Action to Column Creation                                                                                                                                                                                                | Erebus › Code Changes (Columns)       | Ready / no         | `column-create-cancel`                              | Nothing seems to work, no esc, nothing, move to in progerss, fail                                                                                                       |
| 15  | `todo-1781479892635-11fa9a76` | Consolidate Prompt Settings UI Dropdowns                                                                                                                                                                                            | Erebus › Code Changes (Settings Menu) | — / no             | `prompt-cards-mode-dropdown`                        | Uncetain what changes were made and what the agent thought it did, fail, move to in progress                                                                            |
| 16  | `todo-1779922111442-e8ee55be` | Add Toast Notification for Column Restrictions                                                                                                                                                                                      | Erebus › Code Changes (Columns)       | Ready / no         | `dnd-blocked-search-toast`                          | Move to In review                                                                                                                                                       |
| 17  | `todo-1782837497890-091d8d81` | Fix Drag-and-Drop Scrolling with Context Windows                                                                                                                                                                                    | Erebus › Code Changes (Drag and Drop) | Unrefined / no     | `dnd-scroll-context-windows`                        | Pass - Mark / Check Completed                                                                                                                                           |
| 18  | `todo-1782595846467-59f2c25a` | Prevent AI card focus stealing from active windows                                                                                                                                                                                  | Erebus › Code Changes (Ai)            | Ready / no         | `refresh-preserves-focus`                           | Move to In review                                                                                                                                                       |
| 19  | `todo-1779729416842-846d95e5` | Prevent re-render from causing typing window to lose focus when parallel actions complete during card editing or addition.                                                                                                          | Erebus › Code Changes (Ai)            | — / no             | `refresh-preserves-focus`                           | Move to In Review                                                                                                                                                       |
| 20  | `todo-1778818163209`          | Resolve Browser Search Focus Loss Issue                                                                                                                                                                                             | Erebus › Code Changes (Search)        | Ready / no         | `refresh-preserves-focus`                           | Pass - Mark / Check Completed                                                                                                                                           |
| 21  | `todo-1779650321787`          | Refreshes still cause the column scroll to move to a new location, like it jitters a bit, and it's distracting. A static location should persist.                                                                                   | Erebus › Code Changes (Scrolling)     | — / no             | `refresh-preserves-focus`                           | Pass - Mark / Check Completed                                                                                                                                           |
| 22  | `todo-1786397388179-416fe294` | Add Shortcut For Global Card Collapse State                                                                                                                                                                                         | Erebus › Code Changes (Notes)         | Ready / no         | `notes-collapse-all-shortcut`                       | Unceratin what and where this might exist, fail, move to in progress.                                                                                                   |
| 23  | `todo-1779908027238`          | Implement Search Filter for Board Menu                                                                                                                                                                                              | Erebus › Ideas                        | Ready / no         | `board-menu-search`                                 | Move to In Review                                                                                                                                                       |
| 24  | `todo-1781119245365-e4598e49` | Maintain Card Context During Scroll                                                                                                                                                                                                 | Erebus › Code Changes (Scrolling)     | — / no             | `notes-sticky-header`                               | Move to In Review                                                                                                                                                       |
| 25  | `todo-1781911686573-673f7564` | Manage Model Capabilities in Settings                                                                                                                                                                                               | Erebus › Code Changes (Ai)            | — / no             | `model-capabilities-settings`                       | Unceratin what and where this might exist, fail, move to in progress.                                                                                                   |
| 26  | `todo-1781477271814-7daac5dc` | Navigate to Search Result Board Location                                                                                                                                                                                            | Erebus › Ideas                        | Ready / no         | `search-result-goto-board`                          | Unceratin what and where this might exist, fail, move to in progress.                                                                                                   |
| 27  | `todo-1784224051021-23968099` | Investigate voice to text toast notification issues                                                                                                                                                                                 | Erebus › Code Changes (UI)            | Ready / no         | `voice-toast-lifecycle`                             | Pass - Mark / Check Completed                                                                                                                                           |
| 28  | `todo-1782582701567-7915376d` | Add Language Selection Dropdown to Code Blocks *(Partial — saved notes (Dantalion surface, separate repo) not covered)*                                                                                                             | Erebus › Code Changes (Markdown)      | Ready / no         | `code-block-language`                               | Unceratin what and where this might exist, fail, move to in progress.                                                                                                   |
| 29  | `todo-1781390341573-daeb2550` | Implement User Rebindable Shortcut Key Settings                                                                                                                                                                                     | Erebus › Requires Testing             | In Review / no     | `verify-requires-testing`                           | Move to In Review                                                                                                                                                       |
| 30  | `todo-1782483622185-4649f400` | Resolve UI Overlap and Scrolling Issues                                                                                                                                                                                             | Erebus › Requires Testing             | In Review / no     | `verify-requires-testing`                           | Move to In Review                                                                                                                                                       |
| 31  | `todo-1779921748180-601fd273` | Fix menu opening behavior: ensure the screen only shifts/bumps in if the menu is opened while scrolled to the far left of the board. Opening the menu from any other horizontal scroll position should not disrupt the user's view. | Erebus › Code Changes (Scrolling)     | — / no             | `verify-requires-testing`, `side-panel-layout-lock` | Move to In Review                                                                                                                                                       |
| 32  | `todo-1780062675318-38aff93d` | Fix Board Menu Refresh Bug                                                                                                                                                                                                          | Erebus › Code Changes (Columns)       | Ready / no         | `board-menu-refresh`                                | Move to In Review                                                                                                                                                       |
| 33  | `todo-1783009933981`          | Implement Collapsible Cards for Space Optimization                                                                                                                                                                                  | Erebus › Code Changes (Cards)         | Unrefined / no     | `collapsible-board-cards`                           | Unceratin what and where this might exist, fail, move to in progress.                                                                                                   |
| 34  | `todo-1779934235007-e43b6e15` | Implement Customizable and Persistent Column Resizing                                                                                                                                                                               | Erebus › Ideas                        | Ready / no         | `column-resize-persist`                             | Unceratin what and where this might exist, fail, move to in progress.                                                                                                   |
| 35  | `todo-1781402215730-435526d8` | Enhance System Logging for Pipeline Prompts                                                                                                                                                                                         | Erebus › Code Changes (Ai)            | — / no             | `logging-levels`                                    | Move to In Review                                                                                                                                                       |
| 36  | `todo-1778825245920`          | Cut down on logs displayed in Console                                                                                                                                                                                               | Erebus › Clean Up                     | — / no             | `logging-levels`                                    | Move to In Review                                                                                                                                                       |
| 37  | `todo-1779650490015`          | Need in logs a way to capture logs for testing purposes to turn on, and main logs that will always persist as part of the standard operation.                                                                                       | Erebus › Icebox                       | Unrefined / no     | `logging-levels`                                    | Move to In Review                                                                                                                                                       |
| 38  | `todo-1787724462518-c49d8e05` | Standardize System Color Modes and Theme Support                                                                                                                                                                                    | Erebus › Code Changes (UI)            | In Progress / no   | `theme-contrast`                                    | Move to In Review                                                                                                                                                       |
| 39  | `todo-1780939416796-d651f2a0` | Implement Context-Aware Helper Tooltips for Voice Input                                                                                                                                                                             | Erebus › Ideas                        | Ready / no         | `voice-helper-tooltips`                             | Pass - Mark / Check Completed                                                                                                                                           |
| 40  | `todo-1782761235404-e93fa422` | Implement structured delimiter markers for AI prompts                                                                                                                                                                               | Erebus › Code Changes (Ai)            | Unrefined / no     | `prompt-delimiters`                                 | Move to In Review                                                                                                                                                       |
| 41  | `todo-1779754020437-d4d5b65e` | Update all instances of Ai to be dynamic to follow the model; use 'ai' or similar as the ref to simplify for UI/UX.                                                                                                                 | Erebus › Code Changes (Ai)            | — / no             | `ai-label-dynamic`                                  | Unceratin what and where this might exist, fail, move to in progress.                                                                                                   |
| 42  | `todo-1779726396198-8035776f` | Fix scroll jump when interacting with a task card at the bottom of the board                                                                                                                                                        | Erebus › Code Changes (Scrolling)     | — / no             | `scroll-jump-bottom-card`                           | Unceratin what and where this might exist, fail, move to in progress.                                                                                                   |
| 43  | `todo-1782484657689-8a2aaa7d` | Implement Chain of Action Visual UI Workflow *(Partial by scope — second sub-note of the card only; the chain-of-action canvas (first sub-note) not done)*                                                                          | Erebus › Code Changes (Ai)            | Unrefined / no     | `manual-prompt-selection`                           | Not Done to the best of my knowledge, fail move to in progress                                                                                                          |




## B. Packages with no card — found during the sweep (14)


| #   | Package                           | What was found                                                                                                                                                                                                                                                                                                                                                                                                                        | Merge     |
| --- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| 1   | `test-data-isolation`             | *found during the sweep, no card* — `tests/gemma-normalize.test.js` boots `server.js` against the default `data/` directory, which in the main checkout is the live data                                                                                                                                                                                                                                                              | `178711f` |
| 2   | `default-tag-rename-persist`      | *found during the sweep* — renaming a built-in color tag (Backend, Bug, …) saves, but a phantom tag with the old name returns on reload (`rebuildGlobalTagsFromState` always re-adds the built-in list)                                                                                                                                                                                                                               | `b8d0667` |
| 3   | `stale-test-repair`               | *found during the sweep* — the 3 long-standing failures (`keeps all card actions in one menu definition`, `keeps AI note reveal targets across reload…`, `wires Ctrl+Shift+Backslash…`) have been carried as "known" since June; decide per test whether the code or the assertion is wrong and restore a fully green suite                                                                                                           | `2605abf` |
| 4   | `ai-refine-drops-items`           | *found during the sweep* — same class as 1.1 on sibling paths: automatic refine-card keeps only `taskEntries[0]` when the classifier says 1 but the model returns several (`server.js` ~2007); the refine replace path drops entries equal to the current text and then deletes the original (~1945); add-task with a child note keeps only the first item (~1771)                                                                    | `06fefc1` |
| 5   | `integrity-followups`             | *found during the sweep* — `POST /todos` with an unknown `columnId` saves a card no board can show (201); the `deleteTodo` failure path reloads without `forceRefresh`, so the gate skips restoring the card; `/tasksOrder` still echoes `error.message` for non-storage errors                                                                                                                                                       | `06327b8` |
| 6   | `ai-note-drops-items`             | *found during the sweep* — `getGemmaNoteText` (`server.js` ~480-518) reads only `items[0]`, so add-note, refine-note, note Prompt Injection and child-note generation drop items 2..n when the model returns a list for a note                                                                                                                                                                                                        | `1964e81` |
| 7   | `prompt-injection-refresh-resume` | *found during the sweep* — draft Prompt Injection jobs are persisted but `loadGemmaPendingJobsFromStorage` drops `prompt-injection-task-draft` / `-note-draft` on reload, so a refresh mid-job loses the result (and for multi-card, the board never reloads to show the created cards); with focus in the Prompt Injection window during voice, Escape closes the window and hard-stops voice and board shortcuts are not suppressed | `40ea134` |
| 8   | `notes-write-race`                | *found during the sweep* — `server.js` reads notes and writes them back as separate DAL operations, sometimes around a model call, so a note edited in between is overwritten; `dal.readNotes`/`writeNotes` are outside the snapshot-conflict check added by 1.3                                                                                                                                                                      | `cd93687` |
| 9   | `secret-redaction`                | *found during the sweep* — `GET /data` returns stored model `apiKey` values raw (it bypasses `toPublicModelRecord`), and `GET /api/models` returns `apiKeyEnvVar` verbatim; in the live `models.json` all three models hold what looks like a real Google API key **in the** `apiKeyEnvVar` **field** (meant for a variable *name*), so the key is served in plain text to any local page                                             | `7a0472a` |
| 10  | `test-walk-race`                  | *found during the sweep* — `markdown-kit-package.test.js` walked the repo while other suites deleted their `data-test-`* folders, causing an intermittent ENOENT under `--test-concurrency`                                                                                                                                                                                                                                           | `df177e5` |
| 11  | `qa-findings`                     | *found by the integration QA pass (all pre-existing on* `ee8e2de`*)* — F1 Escape with a note menu open closes the whole notes pane; F2 at ~900 px a column can't be dragged one place right (stale sortable positions after auto-scroll); F3 a lock that also blocks reads gives a generic 500 instead of the "locked" toast; F4 the Prompt Injection window can open partly off-screen (assumes 220 px, is ~295 px)                  | `905623f` |
| 12  | `ai-ui-followups`                 | *found by sweep agents* — busy add-task button relabelled idle on a model switch; missing-key message always names Gemini; expanded AI activity panel sits above the Settings dialog; OpenAPI job-type enums omit the two draft Prompt Injection types                                                                                                                                                                                | `b3ebb50` |
| 13  | `prompt-injection-window-polish`  | *found by sweep agents* — Escape in the window (no voice) closes the notes pane and can raise the discard dialog; the window ignores Light/Dark themes; its two prompt selects (template text vs formatting profile) need unmistakable labels                                                                                                                                                                                         | `df51b22` |
| 14  | `integration-qa-2`                | *found by integration QA pass 2* — the Prompt Injection voice tip still named the old "Prompt template" select and said it applies a format (interaction of `voice-helper-tooltips` and `prompt-injection-window-polish`)                                                                                                                                                                                                             | `1b4cda0` |




## C. All 51 packages in merge order, with the files each touched

Revert any one package with `git revert -m 1 <merge>` on `local-fixes`.

### 1. `fix/search-bar-right-gap` — merge `33d7769` (plan 3.7)

- **Subject:** collapse search without right-side gap
- **Cards:** `todo-1782595555320-b0df9186` Fix search bar right side padding
- **Size:** 2 files changed, 153 insertions(+), 5 deletions(-)
- **Files (2):** `public/todoliststyles2.css`, `tests/search-bar-right-gap.test.js`



### 2. `fix/settings-scrollbar-style` — merge `5938104` (plan 3.8)

- **Subject:** settings scrollbars follow app style
- **Cards:** `todo-1782760132922-97997fda` Update settings menu scroll bar styles
- **Size:** 2 files changed, 336 insertions(+), 3 deletions(-)
- **Files (2):** `public/todoliststyles2.css`, `tests/settings-scrollbar-style.test.js`



### 3. `fix/toast-stack-overflow` — merge `a4de30c` (plan 3.6)

- **Subject:** AI activity toast stays in the viewport
- **Cards:** `todo-1779650286782` When generating a significant amount of Ai requests, the toast message goes off screen, it should scroll
- **Size:** 3 files changed, 301 insertions(+)
- **Files (3):** `public/todolist2.js`, `public/todoliststyles2.css`, `tests/toast-stack-overflow.test.js`



### 4. `fix/tag-window-second-tag-edit` — merge `6b8b636` (plan 3.9)

- **Subject:** Escape cancels only the tag rename
- **Cards:** `todo-1778824878134` Edit in Tag window for 2nd tag doesn't work
- **Size:** 2 files changed, 275 insertions(+), 1 deletion(-)
- **Files (2):** `public/todolist2.js`, `tests/tag-window-second-tag-edit.test.js`



### 5. `fix/new-task-autoscroll` — merge `fd70cf0` (plan 2.3)

- **Subject:** reveal AI-created cards in their column
- **Cards:** `todo-1781111162493-5a1e671f` Fix Auto-Scroll for New Column Tasks
- **Size:** 2 files changed, 290 insertions(+)
- **Files (2):** `public/todolist2.js`, `tests/new-task-autoscroll.test.js`



### 6. `fix/ai-multi-card-persist` — merge `d8fe328` (plan 1.1)

- **Subject:** persist every Prompt Injection card
- **Cards:** `todo-1787694813073-54eb6118` Investigate Prompt Injection Multi-Card Generation Bug
- **Size:** 4 files changed, 717 insertions(+), 11 deletions(-)
- **Files (4):** `openapi.js`, `public/todolist2.js`, `server.js`, `tests/ai-multi-card-persist.test.js`



### 7. `fix/move-menu-alpha-order` — merge `8eca7fc` (plan 3.3)

- **Subject:** natural-order move destinations
- **Cards:** `todo-1778984818921` Moving UI shows columns to move into not in alphabetical order.
- **Review history:** Sent back once (default board; placement label)
- **Size:** 2 files changed, 560 insertions(+), 8 deletions(-)
- **Files (2):** `public/todolist2.js`, `tests/move-menu-alpha-order.test.js`



### 8. `fix/write-failure-feedback` — merge `5bbca13` (plan 1.2)

- **Subject:** tell the user when a save did not land
- **Cards:** `todo-1708048105823` Implement Database Sync Error Handling Policy
- **Size:** 6 files changed, 950 insertions(+), 18 deletions(-)
- **Files (6):** `dal.js`, `openapi.js`, `public/apiService.js`, `public/todolist2.js`, `server.js`, `tests/write-failure-feedback.test.js`



### 9. `fix/auto-sort-on-change` — merge `ff8343f` (plan 2.2)

- **Subject:** re-sort columns when sorted fields change
- **Cards:** `todo-1779739234482-55b57f70` Resolve Automatic Sorting Issue for Completed Items
- **Review history:** Merge committed before tests finished (orchestrator error); 2 tests fixed in 7b081a8
- **Size:** 4 files changed, 617 insertions(+), 7 deletions(-)
- **Files (4):** `public/columnSort.js`, `public/todolist2.js`, `tests/auto-sort-on-change.test.js`, `tests/column-actions.test.js`



### 10. `fix/test-data-isolation` — merge `178711f` (plan 5.5)

- **Subject:** (isolate test suites from the repo data directory)
- **Cards:** none — found during the sweep
- **Size:** 6 files changed, 273 insertions(+), 2 deletions(-)
- **Files (6):** `.gitignore`, `tests/checklist-format.test.js`, `tests/file-attachments.test.js`, `tests/gemma-normalize.test.js`, `tests/openapi.test.js`, `tests/test-data-isolation.test.js`



### 11. `fix/dnd-placeholder-line` — merge `41a6a8a` (plan 3.4)

- **Subject:** thin drop line in every column
- **Cards:** `todo-1779025832029` Fix Column Drag-and-Drop Visual Spacing
- **Size:** 2 files changed, 220 insertions(+), 4 deletions(-)
- **Files (2):** `public/todoliststyles2.css`, `tests/dnd-placeholder-line.test.js`



### 12. `fix/default-tag-rename-persist` — merge `b8d0667` (plan 3.11)

- **Subject:** renamed built-in tags stay renamed
- **Cards:** none — found during the sweep
- **Size:** 2 files changed, 515 insertions(+), 8 deletions(-)
- **Files (2):** `public/todolist2.js`, `tests/default-tag-rename-persist.test.js`



### 13. `fix/card-move-integrity` — merge `71d227d` (plan 1.3)

- **Subject:** cards can no longer be lost by moves
- **Cards:** `todo-1778620266948` Investigate Data Loss During Card Moves
- **Size:** 4 files changed, 1288 insertions(+), 41 deletions(-)
- **Files (4):** `dal.js`, `openapi.js`, `server.js`, `tests/card-move-integrity.test.js`



### 14. `fix/stale-test-repair` — merge `2605abf` (plan 5.6)

- **Subject:** suite fully green
- **Cards:** none — found during the sweep
- **Size:** 2 files changed, 231 insertions(+), 9 deletions(-)
- **Files (2):** `tests/card-actions.test.js`, `tests/gemma-ui.test.js`



### 15. `fix/column-delete-flash` — merge `b300fd3` (plan 3.2)

- **Subject:** column leaves the board once
- **Cards:** `todo-1779025915731` Fix column deletion visual flash bug
- **Size:** 4 files changed, 768 insertions(+), 10 deletions(-)
- **Files (4):** `public/columnRemoval.js`, `public/index.html`, `public/todolist2.js`, `tests/column-delete-flash.test.js`



### 16. `fix/status-reorder-settings` — merge `10d257e` (plan 4.1)

- **Subject:** reorder statuses in settings
- **Cards:** `todo-1783610886391-e7583884` Enable Custom Sorting for Status Workflow Settings
- **Size:** 7 files changed, 825 insertions(+), 2 deletions(-)
- **Files (7):** `dal.js`, `openapi.js`, `public/apiService.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `server.js`, `tests/status-reorder-settings.test.js`



### 17. `fix/column-create-cancel` — merge `fa2d0c3` (plan 3.1)

- **Subject:** Escape or click-away cancels a new column
- **Cards:** `todo-1779570847318` Add Cancel Action to Column Creation
- **Review history:** Sent back once (draft wiped by re-render)
- **Size:** 3 files changed, 746 insertions(+)
- **Files (3):** `public/shortcutController.js`, `public/todolist2.js`, `tests/column-create-cancel.test.js`



### 18. `fix/prompt-cards-mode-dropdown` — merge `33c7699` (plan 4.5)

- **Subject:** one Cards select in prompt settings
- **Cards:** `todo-1781479892635-11fa9a76` Consolidate Prompt Settings UI Dropdowns
- **Size:** 3 files changed, 367 insertions(+), 25 deletions(-)
- **Files (3):** `public/todolist2.js`, `tests/gemma-ui.test.js`, `tests/prompt-cards-mode-dropdown.test.js`



### 19. `fix/dnd-blocked-search-toast` — merge `a25a8a5` (plan 3.5)

- **Subject:** say why a drag is blocked by search
- **Cards:** `todo-1779922111442-e8ee55be` Add Toast Notification for Column Restrictions
- **Size:** 2 files changed, 498 insertions(+)
- **Files (2):** `public/todolist2.js`, `tests/dnd-blocked-search-toast.test.js`



### 20. `fix/ai-refine-drops-items` — merge `06fefc1` (plan 1.4)

- **Subject:** AI jobs stop silently dropping items
- **Cards:** none — found during the sweep
- **Size:** 5 files changed, 793 insertions(+), 21 deletions(-)
- **Files (5):** `openapi.js`, `public/todolist2.js`, `server.js`, `tests/ai-refine-drops-items.test.js`, `tests/gemma-ui.test.js`



### 21. `fix/dnd-scroll-context-windows` — merge `7f11aa0` (plan 3.10)

- **Subject:** drag auto-scroll beside open panes
- **Cards:** `todo-1782837497890-091d8d81` Fix Drag-and-Drop Scrolling with Context Windows
- **Size:** 3 files changed, 514 insertions(+), 21 deletions(-)
- **Files (3):** `public/boardScroll.js`, `public/todolist2.js`, `tests/dnd-scroll-context-windows.test.js`



### 22. `fix/refresh-preserves-focus` — merge `7b779c6` (plan 2.1)

- **Subject:** background work stops interrupting the user
- **Cards:** `todo-1782595846467-59f2c25a` Prevent AI card focus stealing from active windows; `todo-1779729416842-846d95e5` Prevent re-render from causing typing window to lose focus when parallel actions complete during card editing or addition.; `todo-1778818163209` Resolve Browser Search Focus Loss Issue; `todo-1779650321787` Refreshes still cause the column scroll to move to a new location, like it jitters a bit, and it's distracting. A static location should persist.
- **Size:** 6 files changed, 1300 insertions(+), 53 deletions(-)
- **Files (6):** `public/index.html`, `public/renderPreservation.js`, `public/todolist2.js`, `tests/gemma-ui.test.js`, `tests/new-task-autoscroll.test.js`, `tests/refresh-preserves-focus.test.js`



### 23. `fix/notes-collapse-all-shortcut` — merge `17316df` (plan 4.4)

- **Subject:** toggle all notes with Ctrl+Shift+[
- **Cards:** `todo-1786397388179-416fe294` Add Shortcut For Global Card Collapse State
- **Size:** 2 files changed, 693 insertions(+), 9 deletions(-)
- **Files (2):** `public/todolist2.js`, `tests/notes-collapse-all-shortcut.test.js`



### 24. `fix/board-menu-search` — merge `ac12108` (plan 4.2)

- **Subject:** filter the board menu as you type
- **Cards:** `todo-1779908027238` Implement Search Filter for Board Menu
- **Size:** 6 files changed, 1062 insertions(+)
- **Files (6):** `public/boardMenuFilter.js`, `public/index.html`, `public/shortcutController.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/board-menu-search.test.js`



### 25. `fix/notes-sticky-header` — merge `a85fded` (plan 4.3)

- **Subject:** notes pane headers stay pinned and usable
- **Cards:** `todo-1781119245365-e4598e49` Maintain Card Context During Scroll
- **Size:** 3 files changed, 498 insertions(+), 12 deletions(-)
- **Files (3):** `public/todolist2.js`, `public/todoliststyles2.css`, `tests/notes-sticky-header.test.js`



### 26. `fix/integrity-followups` — merge `06327b8` (plan 1.6)

- **Subject:** close three small integrity gaps
- **Cards:** none — found during the sweep
- **Size:** 5 files changed, 760 insertions(+), 31 deletions(-)
- **Files (5):** `dal.js`, `openapi.js`, `public/todolist2.js`, `server.js`, `tests/integrity-followups.test.js`



### 27. `fix/model-capabilities-settings` — merge `5864221` (plan 4.8)

- **Subject:** edit model capabilities in settings
- **Cards:** `todo-1781911686573-673f7564` Manage Model Capabilities in Settings
- **Size:** 7 files changed, 1010 insertions(+), 1 deletion(-)
- **Files (7):** `dal.js`, `openapi.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `server.js`, `tests/api.test.js`, `tests/model-capabilities-settings.test.js`



### 28. `fix/search-result-goto-board` — merge `d223f80` (plan 4.6)

- **Subject:** View on Board from search results
- **Cards:** `todo-1781477271814-7daac5dc` Navigate to Search Result Board Location
- **Size:** 7 files changed, 1061 insertions(+), 6 deletions(-)
- **Files (7):** `public/boardScroll.js`, `public/cardActions.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/card-actions.test.js`, `tests/dnd-scroll-context-windows.test.js`, `tests/search-result-goto-board.test.js`



### 29. `fix/ai-note-drops-items` — merge `1964e81` (plan 1.7)

- **Subject:** note paths keep every generated item
- **Cards:** none — found during the sweep
- **Size:** 3 files changed, 650 insertions(+), 14 deletions(-)
- **Files (3):** `openapi.js`, `server.js`, `tests/ai-note-drops-items.test.js`



### 30. `fix/prompt-injection-refresh-resume` — merge `40ea134` (plan 2.7)

- **Subject:** Prompt Injection survives refresh
- **Cards:** none — found during the sweep
- **Size:** 3 files changed, 867 insertions(+), 32 deletions(-)
- **Files (3):** `public/todolist2.js`, `tests/gemma-ui.test.js`, `tests/prompt-injection-refresh-resume.test.js`



### 31. `fix/notes-write-race` — merge `cd93687` (plan 1.5)

- **Subject:** note edits can no longer be overwritten
- **Cards:** none — found during the sweep
- **Review history:** Sent back once (semantic conflict with ai-refine-drops-items)
- **Size:** 7 files changed, 1391 insertions(+), 103 deletions(-)
- **Files (7):** `dal.js`, `openapi.js`, `server.js`, `tests/ai-multi-card-persist.test.js`, `tests/ai-refine-drops-items.test.js`, `tests/gemma-normalize.test.js`, `tests/notes-write-race.test.js`



### 32. `fix/voice-toast-lifecycle` — merge `c59b335` (plan 4.9)

- **Subject:** voice toast lives exactly as long as the session
- **Cards:** `todo-1784224051021-23968099` Investigate voice to text toast notification issues
- **Size:** 4 files changed, 887 insertions(+), 31 deletions(-)
- **Files (4):** `public/todolist2.js`, `public/todoliststyles2.css`, `tests/dnd-blocked-search-toast.test.js`, `tests/voice-toast-lifecycle.test.js`



### 33. `fix/code-block-language` — merge `87b3388` (plan 4.11)

- **Subject:** language label and picker on code blocks
- **Cards:** `todo-1782582701567-7915376d` Add Language Selection Dropdown to Code Blocks
- **Scope:** Partial — saved notes (Dantalion surface, separate repo) not covered
- **Size:** 8 files changed, 893 insertions(+), 13 deletions(-)
- **Files (8):** `packages/markdown-kit/README.md`, `packages/markdown-kit/src/markdown-editor.js`, `packages/markdown-kit/src/markdown-renderer.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/code-block-language.test.js`, `tests/markdown-kit-package.test.js`, `tests/markdown-renderer.test.js`



### 34. `fix/verify-requires-testing` — merge `aa35c8b` (plan 2.6)

- **Subject:** fix what failed in Requires Testing
- **Cards:** `todo-1781390341573-daeb2550` Implement User Rebindable Shortcut Key Settings; `todo-1782483622185-4649f400` Resolve UI Overlap and Scrolling Issues; `todo-1779921748180-601fd273` Fix menu opening behavior: ensure the screen only shifts/bumps in if the menu is opened while scrolled to the far left of the board. Opening the menu from any other horizontal scroll position should not disrupt the user's view.
- **Size:** 4 files changed, 499 insertions(+), 12 deletions(-)
- **Files (4):** `public/shortcutController.js`, `public/shortcutRegistry.js`, `public/todolist2.js`, `tests/verify-requires-testing.test.js`



### 35. `fix/board-menu-refresh` — merge `b12c161` (plan 2.4)

- **Subject:** board menu follows background data
- **Cards:** `todo-1780062675318-38aff93d` Fix Board Menu Refresh Bug
- **Size:** 3 files changed, 829 insertions(+), 1 deletion(-)
- **Files (3):** `public/boardData.js`, `public/todolist2.js`, `tests/board-menu-refresh.test.js`



### 36. `fix/secret-redaction` — merge `7a0472a` (plan 5.7)

- **Subject:** no API response carries a stored secret
- **Cards:** none — found during the sweep
- **Size:** 8 files changed, 1058 insertions(+), 7 deletions(-)
- **Files (8):** `dal.js`, `modelSecrets.js`, `openapi.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `server.js`, `tests/api.test.js`, `tests/secret-redaction.test.js`



### 37. `fix/collapsible-board-cards` — merge `3a1c35d` (plan 4.13)

- **Subject:** collapse cards on the board
- **Cards:** `todo-1783009933981` Implement Collapsible Cards for Space Optimization
- **Size:** 9 files changed, 1247 insertions(+), 7 deletions(-)
- **Files (9):** `public/cardActions.js`, `public/cardCollapse.js`, `public/columnActions.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/card-actions.test.js`, `tests/collapsible-board-cards.test.js`, `tests/column-actions.test.js`



### 38. `fix/column-resize-persist` — merge `1f708d0` (plan 4.7)

- **Subject:** resizable columns that keep their width
- **Cards:** `todo-1779934235007-e43b6e15` Implement Customizable and Persistent Column Resizing
- **Size:** 12 files changed, 1846 insertions(+), 5 deletions(-)
- **Files (12):** `dal.js`, `openapi.js`, `public/apiService.js`, `public/columnActions.js`, `public/columnWidths.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `server.js`, `tests/collapsible-board-cards.test.js`, `tests/column-actions.test.js`, `tests/column-resize-persist.test.js`



### 39. `fix/side-panel-layout-lock` — merge `d59c4c8` (plan 2.8)

- **Subject:** open board menu no longer jumps the board
- **Cards:** `todo-1779921748180-601fd273` Fix menu opening behavior: ensure the screen only shifts/bumps in if the menu is opened while scrolled to the far left of the board. Opening the menu from any other horizontal scroll position should not disrupt the user's view.
- **Size:** 3 files changed, 547 insertions(+), 7 deletions(-)
- **Files (3):** `public/todolist2.js`, `tests/search-shortcuts.test.js`, `tests/side-panel-layout-lock.test.js`



### 40. `fix/logging-levels` — merge `918e32c` (plan 5.1)

- **Subject:** leveled logging, no payloads in the console
- **Cards:** `todo-1781402215730-435526d8` Enhance System Logging for Pipeline Prompts; `todo-1778825245920` Cut down on logs displayed in Console; `todo-1779650490015` Need in logs a way to capture logs for testing purposes to turn on, and main logs that will always persist as part of the standard operation.
- **Size:** 11 files changed, 1213 insertions(+), 173 deletions(-)
- **Files (11):** `README.md`, `dal.js`, `gemmaNormalize.js`, `logger.js`, `public/apiService.js`, `public/index.html`, `public/logger.js`, `public/todolist2.js`, `server.js`, `tests/gemma-normalize.test.js`, `tests/logging-levels.test.js`



### 41. `fix/theme-contrast` — merge `d17da96` (plan 5.4)

- **Subject:** every theme meets contrast minimums
- **Cards:** `todo-1787724462518-c49d8e05` Standardize System Color Modes and Theme Support
- **Review history:** Merge subject overstated: two built-in tag colours still below 4.5:1 (pre-existing)
- **Size:** 5 files changed, 920 insertions(+), 217 deletions(-)
- **Files (5):** `public/theme.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/action-bar-consolidation.test.js`, `tests/theme-contrast.test.js`



### 42. `fix/voice-helper-tooltips` — merge `82c3d97` (plan 4.10)

- **Subject:** phrasing tips while dictating
- **Cards:** `todo-1780939416796-d651f2a0` Implement Context-Aware Helper Tooltips for Voice Input
- **Review history:** One tip went stale after prompt-injection-window-polish; fixed by integration-qa-2
- **Size:** 5 files changed, 1755 insertions(+), 3 deletions(-)
- **Files (5):** `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `public/voiceHints.js`, `tests/voice-helper-tooltips.test.js`



### 43. `fix/test-walk-race` — merge `df177e5` (plan 5.11)

- **Subject:** package-boundary walk ignores temp folders
- **Cards:** none — found during the sweep
- **Size:** 1 file changed, 16 insertions(+), 2 deletions(-)
- **Files (1):** `tests/markdown-kit-package.test.js`



### 44. `fix/prompt-delimiters` — merge `8e127e4` (plan 5.3)

- **Subject:** tagged blocks in every AI prompt
- **Cards:** `todo-1782761235404-e93fa422` Implement structured delimiter markers for AI prompts
- **Size:** 12 files changed, 1126 insertions(+), 149 deletions(-)
- **Files (12):** `gemmaNormalize.js`, `prompts/gemma-child-note-directive-template.md`, `prompts/gemma-formatting-prompt-selection-instructions.md`, `prompts/gemma-prompt-blocks-instructions.md`, `prompts/gemma-prompt-injection-note-directive-template.md`, `prompts/gemma-tag-inventory-context-template.md`, `prompts/gemma-tagging-directive-template.md`, `prompts/gemma-user-text-label.md`, `server.js`, `tests/gemma-normalize.test.js`, `tests/logging-levels.test.js`, `tests/prompt-delimiters.test.js`



### 45. `fix/ai-label-dynamic` — merge `c5e9eeb` (plan 5.2)

- **Subject:** user-visible AI wording is model-agnostic
- **Cards:** `todo-1779754020437-d4d5b65e` Update all instances of Ai to be dynamic to follow the model; use 'ai' or similar as the ref to simplify for UI/UX.
- **Size:** 8 files changed, 589 insertions(+), 115 deletions(-)
- **Files (8):** `gemmaNormalize.js`, `public/apiService.js`, `public/cardActions.js`, `public/todolist2.js`, `server.js`, `tests/ai-label-dynamic.test.js`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`



### 46. `fix/qa-findings` — merge `905623f` (plan 5.8)

- **Subject:** four defects found by integration QA
- **Cards:** none — found during the sweep
- **Size:** 7 files changed, 1161 insertions(+), 21 deletions(-)
- **Files (7):** `dal.js`, `openapi.js`, `public/shortcutController.js`, `public/todolist2.js`, `server.js`, `tests/qa-findings.test.js`, `tests/write-failure-feedback.test.js`



### 47. `fix/scroll-jump-bottom-card` — merge `98097d5` (plan 2.5)

- **Subject:** bottom-scrolled columns hold still
- **Cards:** `todo-1779726396198-8035776f` Fix scroll jump when interacting with a task card at the bottom of the board
- **Size:** 4 files changed, 549 insertions(+), 2 deletions(-)
- **Files (4):** `public/taskVisibility.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/scroll-jump-bottom-card.test.js`



### 48. `fix/manual-prompt-selection` — merge `c2b87b9` (plan 4.14)

- **Subject:** choose the formatting prompt for an AI action
- **Cards:** `todo-1782484657689-8a2aaa7d` Implement Chain of Action Visual UI Workflow
- **Scope:** Partial by scope — second sub-note of the card only; the chain-of-action canvas (first sub-note) not done
- **Review history:** Sent back once (conflicts + 3 silent mis-merges with prompt-delimiters)
- **Size:** 8 files changed, 1438 insertions(+), 33 deletions(-)
- **Files (8):** `openapi.js`, `public/cardActions.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `server.js`, `tests/card-actions.test.js`, `tests/manual-prompt-selection.test.js`, `tests/openapi.test.js`



### 49. `fix/ai-ui-followups` — merge `b3ebb50` (plan 5.9)

- **Subject:** four small AI UI fixes
- **Cards:** none — found during the sweep
- **Size:** 7 files changed, 913 insertions(+), 14 deletions(-)
- **Files (7):** `gemmaNormalize.js`, `modelProviderClient.js`, `openapi.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `server.js`, `tests/ai-ui-followups.test.js`



### 50. `fix/prompt-injection-window-polish` — merge `df51b22` (plan 5.10)

- **Subject:** Escape, theme, and select labels
- **Cards:** none — found during the sweep
- **Size:** 6 files changed, 1002 insertions(+), 29 deletions(-)
- **Files (6):** `public/todolist2.js`, `public/todoliststyles2.css`, `tests/browser-notes-smoke.js`, `tests/manual-prompt-selection.test.js`, `tests/prompt-injection-refresh-resume.test.js`, `tests/prompt-injection-window-polish.test.js`



### 51. `fix/integration-qa-2` — merge `1b4cda0` (plan 5.12)

- **Subject:** correct the stale Prompt Injection voice tip
- **Cards:** none — found during the sweep
- **Size:** 2 files changed, 62 insertions(+), 2 deletions(-)
- **Files (2):** `public/voiceHints.js`, `tests/integration-qa-2.test.js`



## D. Files touched across the whole branch

101 files: 60 added, 40 modified, 1 deleted.

- **Modified (40):** `.gitignore`, `README.md`, `dal.js`, `gemmaNormalize.js`, `modelProviderClient.js`, `openapi.js`, `packages/markdown-kit/README.md`, `packages/markdown-kit/src/markdown-editor.js`, `packages/markdown-kit/src/markdown-renderer.js`, `prompts/gemma-child-note-directive-template.md`, `prompts/gemma-formatting-prompt-selection-instructions.md`, `prompts/gemma-prompt-injection-note-directive-template.md`, `prompts/gemma-tagging-directive-template.md`, `public/apiService.js`, `public/boardData.js`, `public/boardScroll.js`, `public/cardActions.js`, `public/columnActions.js`, `public/columnSort.js`, `public/index.html`, `public/shortcutController.js`, `public/shortcutRegistry.js`, `public/taskVisibility.js`, `public/theme.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `server.js`, `tests/action-bar-consolidation.test.js`, `tests/api.test.js`, `tests/browser-notes-smoke.js`, `tests/card-actions.test.js`, `tests/checklist-format.test.js`, `tests/column-actions.test.js`, `tests/file-attachments.test.js`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`, `tests/markdown-kit-package.test.js`, `tests/markdown-renderer.test.js`, `tests/openapi.test.js`, `tests/search-shortcuts.test.js`
- **Added (60):** `logger.js`, `modelSecrets.js`, `prompts/gemma-prompt-blocks-instructions.md`, `prompts/gemma-tag-inventory-context-template.md`, `public/boardMenuFilter.js`, `public/cardCollapse.js`, `public/columnRemoval.js`, `public/columnWidths.js`, `public/logger.js`, `public/renderPreservation.js`, `public/voiceHints.js`, `tests/ai-label-dynamic.test.js`, `tests/ai-multi-card-persist.test.js`, `tests/ai-note-drops-items.test.js`, `tests/ai-refine-drops-items.test.js`, `tests/ai-ui-followups.test.js`, `tests/auto-sort-on-change.test.js`, `tests/board-menu-refresh.test.js`, `tests/board-menu-search.test.js`, `tests/card-move-integrity.test.js`, `tests/code-block-language.test.js`, `tests/collapsible-board-cards.test.js`, `tests/column-create-cancel.test.js`, `tests/column-delete-flash.test.js`, `tests/column-resize-persist.test.js`, `tests/default-tag-rename-persist.test.js`, `tests/dnd-blocked-search-toast.test.js`, `tests/dnd-placeholder-line.test.js`, `tests/dnd-scroll-context-windows.test.js`, `tests/integration-qa-2.test.js`, `tests/integrity-followups.test.js`, `tests/logging-levels.test.js`, `tests/manual-prompt-selection.test.js`, `tests/model-capabilities-settings.test.js`, `tests/move-menu-alpha-order.test.js`, `tests/new-task-autoscroll.test.js`, `tests/notes-collapse-all-shortcut.test.js`, `tests/notes-sticky-header.test.js`, `tests/notes-write-race.test.js`, `tests/prompt-cards-mode-dropdown.test.js`, `tests/prompt-delimiters.test.js`, `tests/prompt-injection-refresh-resume.test.js`, `tests/prompt-injection-window-polish.test.js`, `tests/qa-findings.test.js`, `tests/refresh-preserves-focus.test.js`, `tests/scroll-jump-bottom-card.test.js`, `tests/search-bar-right-gap.test.js`, `tests/search-result-goto-board.test.js`, `tests/secret-redaction.test.js`, `tests/settings-scrollbar-style.test.js`, `tests/side-panel-layout-lock.test.js`, `tests/status-reorder-settings.test.js`, `tests/tag-window-second-tag-edit.test.js`, `tests/test-data-isolation.test.js`, `tests/theme-contrast.test.js`, `tests/toast-stack-overflow.test.js`, `tests/verify-requires-testing.test.js`, `tests/voice-helper-tooltips.test.js`, `tests/voice-toast-lifecycle.test.js`, `tests/write-failure-feedback.test.js`
- **Deleted (1):** `prompts/gemma-user-text-label.md`



## E. Board cards reviewed but not taken

Listed with reasons in the plan's "Not taken in this sweep, and why" table. They were read, not changed.