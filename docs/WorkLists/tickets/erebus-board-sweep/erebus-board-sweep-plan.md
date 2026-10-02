# Erebus board sweep — plan and live status

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Source of the work | WorkLists board **Erebus** (`board-12`), read from the live server on 2026-09-26 |
| Release line | `main` fast-forwarded and pushed at `ee8e2de` before any fix work started |
| Integration branch | `local-fixes` (cut from `main` at `ee8e2de`). **Nothing in this sweep touches `main`.** |
| Worktrees | `C:\WorkLists-worktrees\<slug>`, one per work package, branch `fix/<slug>` cut from `local-fixes` |
| Started | 2026-09-26 |
| Status | **Owner review done and applied to the board** (9 passed, 19 In Review, 15 In Progress; 2 of those 15 not settable, see Progress log). `local-fixes` at `1b4cda0`; `main` untouched since `ee8e2de` |

## Where it landed — review guide

**State.** `local-fixes` holds **51 work-package merges** on top of `main` (`ee8e2de`), one
`--no-ff` merge commit per package, each subject naming what it fixes and its card id. `main` was
never touched after the initial fast-forward and push. Gates on `local-fixes`: lint pass ·
`node --test --test-concurrency=2 "tests/*.test.js"` **2081 / 2081** (the suite had carried 3 known
failures since June; they are repaired) · `npm run test:browser` **15 / 15**. Two integration QA
passes ran in a real browser against copies of the live data (see Progress log).

**How to review.**
- `git log --first-parent --format="%h %s" main..local-fixes` — one line per package.
- `git show <merge> --stat` / `git diff <merge>^1 <merge>` — one package's full diff.
- Drop a package: `git revert -m 1 <merge-sha>` on `local-fixes` (each package's tests live in
  its own `tests/<slug>.test.js`, so most revert cleanly; a few later merges adapted an earlier
  package's assertions — those are named in the Progress log).
- Run it without touching live data: from `C:\WorkLists-worktrees\local-fixes`, copy
  `data\*.json` to a temp folder and start `PORT=3011 DATA_DIR=<copy> node server.js`.
- When satisfied: fast-forward or merge `local-fixes` into `main`. New stored fields are additive
  and optional (`board.columnWidths`, `model.capabilities`), so the current `main` code ignores
  them if you roll back.

**What needs you** (nothing else is blocked on a decision):

| # | Item | Why it is yours |
| --- | --- | --- |
| 1 | **Rotate the Google API key.** It sits in the `apiKeyEnvVar` field of all 3 models in `data/models.json` (a field meant for a variable *name*), was served to the browser and printed to the browser console by the old refresh log. Move it to the API key field or rely on `GEMINI_API_KEY` in `.env.local` (calls already use that). Also delete note `dee2d636-1706-42d9-b13e-079ec8b5aea3` on card `todo-1790184168113`, which contains the same key string | Live secret and live data |
| 2 | **Live-model smoke test** before merging to `main`: add-task, refine, AI note, and card / note / draft Prompt Injection. Prompt structure changed (5.3) and card Prompt Injection can now split into several cards (1.1) | Only you have the model |
| 3 | **16 legacy broken records** (15 cards their column does not list — 7 in Countdowns › Ideas; 1 "Animal List" card pointing at a column deleted before July). `GET /api/integrity` lists them; nothing was repaired | Live data repair |
| 4 | **Dantalion companion change** so saved notes get the code-block language picker (spec in the 4.11 entry of the Progress log) | Separate repository |
| 5 | **Mermaid in notes** needs a new dependency | Adding packages was out of bounds for agents |
| 6 | **Contrast calls**: Erebus primary buttons (white on `#5b9bd5`, 2.96:1) and control borders (~1.7:1); text on two built-in tag colours in every theme (Information `#5d858f` 4.03:1, orange `#e65100` 3.79:1). All below WCAG and all pre-existing; fixing them changes the look or the tag palette | Visual identity / tag data |
| 7 | Small calls: menu slide 240 ms vs Countdowns' 300 ms; whether Ctrl+F (and similar) should be blocked from shortcut rebinding; the ~57 px temporary strip under a bottom-scrolled column (2.5) vs alternatives; collapsed-card state is per-browser (4.13) | Preference |
| 8 | **Board cards**: the board was read-only during the sweep. After you merge to `main`, I can mark the cards this sweep resolved (card ids in the tables below) through `worklists-card-sync` | Board state should follow `main`, not a local branch |

**Not done and why** — see "Not taken in this sweep"; additionally the "Gemma" identifier/file
rename (Clean Up card `todo-1781283111563`) is left for its own change after `local-fixes` lands,
because it touches almost every file and would bury this sweep's diffs in review.

## Verification ledger — what is complete, what is verified correct, what was wrong

Sources: the merge commits on `local-fixes` (`git log --first-parent main..local-fixes`), each
package's gate results re-run by the orchestrator on the merged tree, and the two integration QA
passes. Vocabulary: **completed** = merged; **verified** = merged and confirmed by a check named
here; **incorrect** = found wrong at review or after merge, with what happened to it.

### Completed

- **51 packages merged** into `local-fixes` (tip `1b4cda0`): 37 reference board cards (43 distinct
  card ids — one of the 37, `side-panel-layout-lock`, is a follow-up found while verifying card
  `todo-1779921748180-601fd273`, which `verify-requires-testing` also covers) and 14 have no card
  (found during the sweep, including the one fix made by QA pass 2). The full per-item list is
  [`erebus-board-sweep-inventory.md`](./erebus-board-sweep-inventory.md).
- **Partial by scope** (stated in the package, not hidden):
  - 4.11 `code-block-language` — board cards, notes-pane preview and note fallback renderer
    done; **saved notes not done** (they render on the Dantalion surface in another repo).
  - 4.14 `manual-prompt-selection` — covers the card's second sub-note only; the first sub-note
    (a visual chain-of-action canvas) was out of scope.
  - 5.1 `logging-levels` — includes Icebox card `todo-1779650490015` folded in deliberately.
- **Held, not done**: 4.12 mermaid (needs a dependency); every row in "Not taken in this sweep".

### Verified correct — and by what

| Check | What it covers | Result |
| --- | --- | --- |
| Per-package gates, run by each agent | lint, full suite, browser smoke on the package branch | all green at hand-back |
| Orchestrator re-run on the merged tree | merges 1–6: the package's own and neighbouring suites after merging; merges 7–9: full suite after the merge commit; **merge 10 onward: full suite before committing each merge** | green except the one exception under "Incorrect"; final **2078 / 2078** |
| Browser smoke on `local-fixes` | `npm run test:browser` after merge 13 (`card-move-integrity`) and after every later merge touching `public/` or `server.js`; earlier merges relied on the agent's own run | **15 / 15** at every run |
| Before/after evidence per package | reproduced the defect on the base, measured it gone after (screenshots + numbers under the scratchpad) | present for every UI package |
| Integration QA pass 1 (tree `40ea134`, 30 merges) | 42 end-to-end behaviours, 1600 px and 900 px, fresh data copies, real server with stubbed model | **42 / 42 PASS**, no regressions; 4 pre-existing defects found → fixed in 5.8 |
| Integration QA pass 2 (final tree `df51b22`) | everything merged after `40ea134`, the final three behaviours, 7 cross-package interactions, and a re-smoke of core flows, at 1600 px and 900 px | **1600: 105 PASS, 2 FAIL, 1 not re-run · 900: 104 PASS, 4 FAIL** — the FAILs are one pre-existing contrast row counted per theme, plus two 900 px rows that failed because the test script did not scroll the card into view (re-run passed). One regression found and fixed (below) |
| Data integrity | `GET /api/integrity` after every QA flow | unchanged: only the 16 legacy records |
| No sweep writes to live data | agents were limited to GETs on the live server and to copies of `data/`; on 2026-09-28 the live files' 101 records modified since 2026-09-26 were scanned for every fixture/probe name the agents used | **0 sweep artefacts.** The live files *have* changed since the sweep began — those are the owner's own edits through the running app (recipes, the Agents board, notes) |

### Incorrect — found and corrected

| What was wrong | Where caught | Resolution |
| --- | --- | --- |
| `move-menu-alpha-order` first version moved the dialog's default board from "Daily Start" to "Agents" (arbitrary either way) | orchestrator review | sent back → opens on the card's own board; agent also fixed a placement-label bug it found |
| `column-create-cancel` first version wiped a typed column title on any background re-render | orchestrator review | sent back → re-render detach told apart from a real click-away |
| `notes-write-race` conflicted semantically with `ai-refine-drops-items` (3 tests failed on a trial merge) | trial merge | merge aborted, sent back → reconciled, plus a replace-vs-note race closed |
| `manual-prompt-selection` conflicted with `prompt-delimiters`; **3 call sites merged "cleanly" but wrongly** (would have silently disabled manual selection) | trial merge → agent reconcile | merge aborted, sent back → fixed, tests added for the silent case |
| **Orchestrator error:** the `auto-sort-on-change` merge (`ff8343f`) was committed before its test run finished; 2 source-contract tests failed | next test run | corrected in the following commit `7b081a8` (both tests asserted adjacency; combined order is reload → re-sort → reveal) |
| Six merge-time test conflicts where two correct packages each asserted their own order/position (menus, reload order, focus gating, board filter stub, voice scopes) | orchestrator merge | each assertion aligned to the combined behaviour, never loosened; named in the merge commit messages |
| Agent brief initially assumed worktrees had data; 20 tests failed with ENOENT in fresh worktrees | first agent report | worktrees seeded with a data copy; root cause fixed properly in 5.5 `test-data-isolation` |
| Three suites had failed since June and were carried as "known" | sweep | 5.6 `stale-test-repair`: all three were stale assertions; suite fully green |
| **Regression from this sweep:** the Prompt Injection voice tip (4.10) still named the old "Prompt template" select and said it applies a format; after 5.10 that select is "Add template text" and does not choose the format | QA pass 2 | fixed in `63b6aa7` (merged as `1b4cda0`) with a test that reads the label the window actually renders |
| **Overstated merge subject:** `fix/theme-contrast` was merged as "every theme meets contrast minimums", but text on two built-in tag colours still fails — Information `#5d858f` 4.03:1, orange `#e65100` 3.79:1 (both failed before the sweep too; tag colours are data) | QA pass 2 + the package's own report | not fixed — needs a darker tag colour or on-tag text colour (owner design call); recorded here so the subject is not read as a claim |

### Incidents (no lasting effect, recorded for honesty)

- One agent stopped another agent's test server on a shared port; the agent that owned it restarted it within a
  minute and both reported green runs. Brief tightened: stop only PIDs you started.
- `git stash` is shared across worktrees; one agent popped another's stash and restored it by SHA
  within the minute. Brief now forbids `git stash`.
- One agent's first probe scripts ran against another agent's server (a temp data copy).
- Two API spend-limit interruptions stopped all running agents; worktrees were intact and each was
  resumed with its context.
- The permission system refused one agent's `git merge local-fixes` inside its worktree; the
  orchestrator's own review-and-merge was unaffected.

### Known side effects of merged fixes (not defects, but visible)

- **Voice toast** (4.9) now persists for the whole session, so at ~900 px it can cover a column's
  own "Stop Listening" button for the session instead of 9 s. The toast's own Stop and Esc work.
- **Bottom-scrolled columns** (2.5) can show a temporary blank strip (~43–57 px) under the last card
  after the Add Task row collapses; it closes as the column scrolls.
- **App toasts** sit over the notes-pane composer's centre (pre-existing geometry, confirmed on
  `ee8e2de`).

### Not verified (limits of the checks)

- **No live AI model** was called anywhere — every AI path ran against a stubbed model. Prompt
  structure (5.3) and multi-card behaviour (1.1, 1.4) need a live smoke test.
- **Real voice** (Web Speech API) does not run headless — voice flows used a fake recognizer.
- The browser's own **Ctrl+F highlight** cannot be automated — the mechanism (unchanged DOM
  nodes) was verified instead.
- **Chromium only** — no Firefox/Safari; no touch.

## Problem → Requirement → Solution

**Problem.** The Erebus board holds 93 open WorkLists cards (excluding Scrapped Ideas) spread across
area columns — `Code Changes (Ai)`, `Code Changes (Columns)`, `Code Changes (Scrolling)` and so on.
Most carry a sub-note with an incident report or a Problem / Requirement / Solution write-up. They
accumulate faster than they are worked, and nothing orders them by what hurts most.

**Requirement.** Work the cards an agent can finish correctly on its own, highest impact first,
without destabilising the release line: every fix lands on its own branch, is reviewed against the
card's own text and the repo's test gates, and only then joins `local-fixes` for the owner to review.

**Solution.** Rank the open cards into tiers (below), run each work package in an isolated git
worktree with its own implementing agent, review each branch's diff, tests and browser evidence,
and merge the ones that hold up into `local-fixes` with `--no-ff` so each package stays one
revertable merge commit.

## How the board was read

- Cards and notes came from `GET /data` and `GET /api/notes` on the running server. **The board is
  treated as read-only for the whole sweep** — no card, note, status or column was written. The
  fixes live on unmerged local branches, so moving a card to "In Review" or ticking checklist rows
  would claim a state the release line does not have yet.
- **Columns map to the area of the app.** `Code Changes (Columns)` is column behaviour,
  `Code Changes (Scrolling)` is scroll behaviour, and so on. That mapping is what groups cards that
  share a root cause into one work package.
- **`completed: true` cards were skipped** even when they still sit in a Code Changes column — the
  owner has already checked them off.
- Sub-notes were read as the real specification. Where a card has several sub-notes (for example
  the Requires Testing overlap card has five incident reports), each one is in scope for that
  package.
- Agents are told how to fetch their own card through the read endpoints
  (`GET /todos/<id>`, `GET /api/notes?eventId=<id>`), per the read half of
  [`worklists-card-sync`](../../../../agents/rules/worklists-card-sync.md). They never write to it.

## Tiers

Ranking rule: **data you can lose > flow that gets interrupted every day > clear, ready bugs >
ready features > hygiene**. Inside a tier, cards whose status is `Ready` go before `Unrefined`.

Status vocabulary: `planned` → `dispatched` → `in review` → `merged` / `sent back` / `rejected`.

### Tier 1 — data integrity

| # | Work package (`fix/<slug>`) | Card(s) | Column | Why here | Status |
| --- | --- | --- | --- | --- | --- |
| 1.1 | `ai-multi-card-persist` | `todo-1787694813073-54eb6118` Investigate prompt injection multi-card generation bug | Code Changes (Ai) | Generated cards silently never reach storage — the only open card that describes content being lost after the user asked for it | merged |
| 1.2 | `write-failure-feedback` | `todo-1708048105823` Database sync error handling policy | Code Changes (Data) | OneDrive locks can defeat the write; the user needs to be told when a save did not land | merged |
| 1.3 | `card-move-integrity` | `todo-1778620266948` Investigate data loss during card moves | Code Changes (Data) | Orphaned cards during moves; investigation plus an integrity check against a copy of the live data | merged |
| 1.4 | `ai-refine-drops-items` | _found during the sweep_ — same class as 1.1 on sibling paths: automatic refine-card keeps only `taskEntries[0]` when the classifier says 1 but the model returns several (`server.js` ~2007); the refine replace path drops entries equal to the current text and then deletes the original (~1945); add-task with a child note keeps only the first item (~1771) | Code Changes (Ai) | Generated content silently discarded | merged |
| 1.5 | `notes-write-race` | _found during the sweep_ — `server.js` reads notes and writes them back as separate DAL operations, sometimes around a model call, so a note edited in between is overwritten; `dal.readNotes`/`writeNotes` are outside the snapshot-conflict check added by 1.3 | Code Changes (Data) | Silent loss of a user's note edit | merged |
| 1.6 | `integrity-followups` | _found during the sweep_ — `POST /todos` with an unknown `columnId` saves a card no board can show (201); the `deleteTodo` failure path reloads without `forceRefresh`, so the gate skips restoring the card; `/tasksOrder` still echoes `error.message` for non-storage errors | Code Changes (Data) | Small, proven gaps next to 1.2 / 1.3 | merged |
| 1.7 | `ai-note-drops-items` | _found during the sweep_ — `getGemmaNoteText` (`server.js` ~480-518) reads only `items[0]`, so add-note, refine-note, note Prompt Injection and child-note generation drop items 2..n when the model returns a list for a note | Code Changes (Ai) | Same class as 1.1 / 1.4 on the note paths | merged |

### Tier 2 — interruptions to daily flow

| # | Work package | Card(s) | Column | Why here | Status |
| --- | --- | --- | --- | --- | --- |
| 2.1 | `refresh-preserves-focus` | `todo-1782595846467-59f2c25a` AI card focus stealing · `todo-1779729416842-846d95e5` re-render loses typing focus · `todo-1778818163209` browser search loses highlight on re-render · `todo-1779650321787` refresh jitters column scroll | Ai / Search / Scrolling | Four cards, one mechanism: a background completion or refresh re-renders the board under the user. One package so the fix is made once | merged |
| 2.2 | `auto-sort-on-change` | `todo-1779739234482-55b57f70` Automatic sorting not reapplied on state changes | Code Changes (Sorting) | Sorted columns show wrong order until a drag | merged |
| 2.3 | `new-task-autoscroll` | `todo-1781111162493-5a1e671f` Auto-scroll to new column tasks regressed | Code Changes (Columns) | Regression of existing behaviour | merged |
| 2.4 | `board-menu-refresh` | `todo-1780062675318-38aff93d` Board menu not refreshing; columns not pulled with card updates | Code Changes (Columns) | Needs a full page reload to see structure changes | merged |
| 2.5 | `scroll-jump-bottom-card` | `todo-1779726396198-8035776f` Scroll jump when interacting with a card at the bottom | Code Changes (Scrolling) | View jumps away from what the user is touching | merged |
| 2.6 | `verify-requires-testing` | `todo-1781390341573-daeb2550` Rebindable shortcut settings · `todo-1782483622185-4649f400` UI overlap and scrolling (5 sub-notes) · `todo-1779921748180-601fd273` menu opening shifts the view | Requires Testing / Scrolling | Two cards sit in Requires Testing; verify each sub-note in a real browser and fix what fails | merged |
| 2.7 | `prompt-injection-refresh-resume` | _found during the sweep_ — draft Prompt Injection jobs are persisted but `loadGemmaPendingJobsFromStorage` drops `prompt-injection-task-draft` / `-note-draft` on reload, so a refresh mid-job loses the result (and for multi-card, the board never reloads to show the created cards); with focus in the Prompt Injection window during voice, Escape closes the window and hard-stops voice and board shortcuts are not suppressed | Code Changes (Ai) | Work lost across a refresh | merged |
| 2.8 | `side-panel-layout-lock` | _found during 2.6_ — `syncSidePanelLayoutMode()` re-decides push/overlay for the open board menu on every render, so a background refresh can jump the board 16–240 px | Code Changes (Scrolling) | Background work moving the view — exactly what 2.1 removed elsewhere | merged |

### Tier 3 — ready bugs, small and contained

| # | Work package | Card(s) | Column | Status |
| --- | --- | --- | --- | --- |
| 3.1 | `column-create-cancel` | `todo-1779570847318` Add cancel action to column creation | Code Changes (Columns) | merged |
| 3.2 | `column-delete-flash` | `todo-1779025915731` Column deletion visual flash | Code Changes (Columns) | merged |
| 3.3 | `move-menu-alpha-order` | `todo-1778984818921` Move UI lists columns out of alphabetical order | Code Changes (Columns) | merged |
| 3.4 | `dnd-placeholder-line` | `todo-1779025832029` Column drag-and-drop visual spacing | Code Changes (Columns) | merged |
| 3.5 | `dnd-blocked-search-toast` | `todo-1779922111442-e8ee55be` Toast when a drag is blocked by active search | Code Changes (Columns) | merged |
| 3.6 | `toast-stack-overflow` | `todo-1779650286782` Many AI toasts run off screen | Code Changes (Ai) | merged |
| 3.7 | `search-bar-right-gap` | `todo-1782595555320-b0df9186` Search bar right-side gap on cancel | Code Changes (Search) | merged |
| 3.8 | `settings-scrollbar-style` | `todo-1782760132922-97997fda` Settings menu scrollbars off-theme | Code Changes (Settings Menu) | merged |
| 3.9 | `tag-window-second-tag-edit` | `todo-1778824878134` Edit in tag window for second tag does not work | Code Changes (Tagging) | merged |
| 3.10 | `dnd-scroll-context-windows` | `todo-1782837497890-091d8d81` Drag auto-scroll fails with notes pane / menu open | Code Changes (Drag and Drop) | merged |
| 3.11 | `default-tag-rename-persist` | _found during the sweep_ — renaming a built-in color tag (Backend, Bug, …) saves, but a phantom tag with the old name returns on reload (`rebuildGlobalTagsFromState` always re-adds the built-in list) | Code Changes (Tagging) | merged |

### Tier 4 — ready features

| # | Work package | Card(s) | Column | Status |
| --- | --- | --- | --- | --- |
| 4.1 | `status-reorder-settings` | `todo-1783610886391-e7583884` Custom sorting for statuses | Code Changes (Settings Menu) | merged |
| 4.2 | `board-menu-search` | `todo-1779908027238` Search filter for the board menu | Ideas | merged |
| 4.3 | `notes-sticky-header` | `todo-1781119245365-e4598e49` Keep card header and actions visible while scrolling notes | Code Changes (Scrolling) | merged |
| 4.4 | `notes-collapse-all-shortcut` | `todo-1786397388179-416fe294` Shortcut for global collapse state | Code Changes (Notes) | merged |
| 4.5 | `prompt-cards-mode-dropdown` | `todo-1781479892635-11fa9a76` Consolidate Single / Multiple card dropdowns | Code Changes (Settings Menu) | merged |
| 4.6 | `search-result-goto-board` | `todo-1781477271814-7daac5dc` View a search result's location on its board | Ideas | merged |
| 4.7 | `column-resize-persist` | `todo-1779934235007-e43b6e15` Customisable, persistent column widths | Ideas | merged |
| 4.8 | `model-capabilities-settings` | `todo-1781911686573-673f7564` Manage model capabilities in settings | Code Changes (Ai) | merged |
| 4.9 | `voice-toast-lifecycle` | `todo-1784224051021-23968099` Voice-to-text toast stop / persistence | Code Changes (UI) | merged |
| 4.10 | `voice-helper-tooltips` | `todo-1780939416796-d651f2a0` Context-aware helper hints during voice input | Ideas | merged |
| 4.11 | `code-block-language` | `todo-1782582701567-7915376d` Language label / dropdown on code blocks | Code Changes (Markdown) | merged (partial — saved notes need a Dantalion change) |
| 4.12 | `mermaid-notes` | `todo-1782486464345-3d8bdae0` Mermaid diagrams in notes (as a separable module) | Code Changes (Notes) | held — needs a new dependency (mermaid); agents may not install packages |
| 4.13 | `collapsible-board-cards` | `todo-1783009933981` Collapsible cards on the board | Code Changes (Cards) | merged |
| 4.14 | `manual-prompt-selection` | second sub-note of `todo-1782484657689-8a2aaa7d` — manual prompt selection | Code Changes (Ai) | merged |

### Tier 5 — AI pipeline and hygiene

| # | Work package | Card(s) | Column | Status |
| --- | --- | --- | --- | --- |
| 5.1 | `logging-levels` | `todo-1781402215730-435526d8` prompt logs name their source file · `todo-1778825245920` cut console noise · `todo-1779650490015` (Icebox) test-only log switch vs always-on logs | Ai / Clean Up | merged |
| 5.2 | `ai-label-dynamic` | `todo-1779754020437-d4d5b65e` UI says "Gemma" regardless of the active model | Code Changes (Ai) | merged |
| 5.3 | `prompt-delimiters` | `todo-1782761235404-e93fa422` Structured delimiter markers in AI prompts | Code Changes (Ai) | merged |
| 5.4 | `theme-contrast` | `todo-1787724462518-c49d8e05` Dark mode items blend together (card's own "Current Status") | Code Changes (UI) | merged |
| 5.5 | `test-data-isolation` | _found during the sweep, no card_ — `tests/gemma-normalize.test.js` boots `server.js` against the default `data/` directory, which in the main checkout is the live data | — | merged |
| 5.6 | `stale-test-repair` | _found during the sweep_ — the 3 long-standing failures (`keeps all card actions in one menu definition`, `keeps AI note reveal targets across reload…`, `wires Ctrl+Shift+Backslash…`) have been carried as "known" since June; decide per test whether the code or the assertion is wrong and restore a fully green suite | — | merged |
| 5.7 | `secret-redaction` | _found during the sweep_ — `GET /data` returns stored model `apiKey` values raw (it bypasses `toPublicModelRecord`), and `GET /api/models` returns `apiKeyEnvVar` verbatim; in the live `models.json` all three models hold what looks like a real Google API key **in the `apiKeyEnvVar` field** (meant for a variable *name*), so the key is served in plain text to any local page | — | merged |
| 5.8 | `qa-findings` | _found by the integration QA pass (all pre-existing on `ee8e2de`)_ — F1 Escape with a note menu open closes the whole notes pane; F2 at ~900 px a column can't be dragged one place right (stale sortable positions after auto-scroll); F3 a lock that also blocks reads gives a generic 500 instead of the "locked" toast; F4 the Prompt Injection window can open partly off-screen (assumes 220 px, is ~295 px) | — | merged |
| 5.9 | `ai-ui-followups` | _found by sweep agents_ — busy add-task button relabelled idle on a model switch; missing-key message always names Gemini; expanded AI activity panel sits above the Settings dialog; OpenAPI job-type enums omit the two draft Prompt Injection types | — | merged |
| 5.10 | `prompt-injection-window-polish` | _found by sweep agents_ — Escape in the window (no voice) closes the notes pane and can raise the discard dialog; the window ignores Light/Dark themes; its two prompt selects (template text vs formatting profile) need unmistakable labels | — | merged |
| 5.11 | `test-walk-race` | _found during the sweep_ — `markdown-kit-package.test.js` walked the repo while other suites deleted their `data-test-*` folders (intermittent ENOENT under `--test-concurrency`) | — | merged |
| 5.12 | `integration-qa-2` | _found by integration QA pass 2_ — the Prompt Injection voice tip named the old "Prompt template" select and said it applies a format | — | merged |

### Not taken in this sweep, and why

| Card(s) | Reason |
| --- | --- |
| Icebox (17), except the log-switch card folded into 5.1 | The owner parked them. Several are one-line ideas with no requirement to test against |
| Blocked: AI normalization strategy, AI voice task creation | Owner-marked Blocked |
| `todo-1783610270478` Board template columns, `todo-1787841819255` keyword metadata | `In Refinement` — the card itself lists unresolved design questions |
| `todo-1782912082812` note header tags, `todo-1782911489721` current-board indicator | Blocked on a design that does not exist yet (stated in their own notes) |
| Voice local STT, text-to-speech, multi-column card mapping | Owner-marked Blocked |
| Card dependency API and blocking UI (4 cards in Ideas (Dependencies)) | One feature split four ways with overlapping, partly contradictory designs; it wants a single spec (the `features/view-topology` epic already exists) before code |
| `todo-1781283111563` Rename "Gemma" across the codebase | Touches nearly every file; running it beside parallel branches guarantees conflicts. Held until the sweep's other merges land |
| `todo-1778976896486` Convert all links to Markdown | A rewrite of live card data, not code; wants the owner's go-ahead on a dry run |
| `todo-1778824800443` per-board data pull, `todo-1778824819237` lighter architecture, SQL cards | Architecture programmes, not tickets |
| `todo-1782595025493` AI status classification, `todo-1779546025842` leaner AI payload, `todo-1780504221804` / `todo-1780504345194` AI generation workflow, chain-of-action canvas, context tray, status grouping view, voice status updates | Either largely delivered by the classification-prompt pipeline already, or needs a live model to verify, or is a multi-week feature. Candidates for a second pass |
| `todo-1782770650099` multi-note injection rate limiting | Investigation with no failing case to test against |
| Can't be replicated (2), Philosophy (2), Scrapped Ideas (9) | Not work items |
| Scheduler ordering interface (Partially Solved) | Depends on the dependency-model decision above |

## Review gate for every branch

A branch merges into `local-fixes` only when all of these hold:

1. The diff does what the card's text and sub-notes ask — checked against the card, not the
   agent's summary.
2. New or changed behaviour has tests in `tests/` (happy, failure, edge where risk exists).
3. `npm run lint` passes; `npm test` shows no failure beyond the three known pre-existing ones
   (`keeps all card actions in one menu definition`, `keeps AI note reveal targets across reload and
   missing server job results`, `wires Ctrl+Shift+Backslash as a context-aware global voice
   shortcut`); `npm run test:browser` passes when UI was touched.
4. UI changes carry real-browser evidence (Playwright against a server started from the worktree on
   a spare port with a **copy** of the live data — never the live data directory).
5. No `!important` or specificity band-aids, no unexplained magic numbers, no drive-by reformatting
   of unrelated code (`browser-loop-guardrails`).

Branches that fail are **sent back** to their agent with the specific finding, or **rejected** with
the reason recorded here.

## Progress log

_Newest first. Each entry names what merged, what was sent back, and the gate results on
`local-fixes` after the merge._

- 2026-09-28 — **Owner review applied to the board.** The verdicts from the inventory's Review
  column were written to the 43 cards: 9 checked Completed, 19 In Review (2 already were),
  13 In Progress. Rows 2 and 15 were rejected by the server: their only tag, `UI/UX`, is not
  status-enabled. They are left unchanged pending the owner's tag call. Details are in the
  WorkLists changelog entry `2026-09-28T19:30:00Z`.
- 2026-09-28 — **Integration QA pass 2 complete** on the final tree (`df51b22`), after a second
  spend-limit interruption and resume. Matrix above ("Verified correct"). **One regression from
  this sweep found and fixed** (stale Prompt Injection voice tip, `63b6aa7`, merged as `1b4cda0`);
  one pre-existing contrast failure (Information tag text 4.03:1) left for the owner; two side
  effects recorded. Final gates on `local-fixes` `1b4cda0`: `npm run lint` pass ·
  `node --test --test-concurrency=4 "tests/*.test.js"` **2081 / 2081** · `npm run test:browser`
  **15 / 15**. Per the owner's instruction, no new packages were started after the interruption;
  only in-progress work was finished.
- 2026-09-26 — **Merged `fix/prompt-injection-window-polish`** (`853aa1a`, `a276ee5`, `5b35c45`):
  Escape in the window now closes only the window (it used to close the notes pane and could raise
  the discard dialog) and returns focus to its opener; voice still stops on the first Escape. The
  window follows Light/Dark through the `--themed-*` aliases (Erebus: 0 differing pixels). The two
  selects now read "Add template text" (pasted ahead of the instruction) and "Formatting"
  (chooses the formatting prompt) — behaviour unchanged. Gate: 2078/2078, browser 15/15.
- 2026-09-26 — **Merged `fix/ai-ui-followups`** (`3a0bfb3`, `de04695`, `0d7eff1`, `355eb9b` — one per
  item): a running add-task button keeps "Running…" through a model switch; the missing-key message
  names the active provider's actual key source (never echoing values); all five `aria-modal`
  overlays share one modal layer above the AI activity panel (Settings › APIs "Activate" was
  unclickable under an expanded panel); OpenAPI job-type enums equal the server's accepted types
  (a test derives the list from `server.js`, so future drift fails). Gate: 2049/2049,
  browser 15/15.
- 2026-09-26 — **Merged `fix/manual-prompt-selection`** (`8997cf9`, reconcile `5e83977`) after the
  send-back. Beyond the 5 textual conflicts, the agent found 3 *silent* mis-merges where git had put
  the requested id into prompt-delimiters' new `promptInput` position (which would have switched
  manual selection off without any test failing) and added tests that a manual choice lands as
  exactly one `<formatting_profile>` block. Owner question left open: the Prompt Injection window
  now has two selects over the same profiles — the older "Prompt template" (pastes the profile
  text into the instruction) and the new "Prompt" (chooses the formatting profile); merge or
  rename? Gate: 2023/2023, browser 15/15.
- 2026-09-26 — **Sent back `fix/manual-prompt-selection`**: approved in design (optional
  `formattingPromptId` skips the model's selection step; unknown id → 400 before queueing; selector
  in the Prompt Injection window plus a new "Refine with Prompt" card action; per-surface session
  memory), but it collides with 5.3's `promptInput` threading (5 server.js conflicts), 5.2's
  label guard, and the Prompt Injection window changes from 4.10 / 5.8 — agent reconciling on its
  branch. Dispatched 5.9 `ai-ui-followups`.
- 2026-09-26 — **Merged `fix/scroll-jump-bottom-card`** (`286167a`): still reproducible after the
  sweep's render fixes, via two mechanisms present since the initial import — the Add Task row's
  blur handler collapsing it 250 ms later (cards drop 43–54 px; an open card menu left 58 px from its
  trigger) and the inline editor being shorter than the rendered markdown (5–24 px, never
  restored). Fix: when an unrequested layout change would shrink a bottom-scrolled column's scroll
  range, the list keeps the difference as temporary empty space after its last card, released as
  the user scrolls. **Visible trade-off for the owner to judge:** a blank strip (up to ~57 px) can sit
  under the last card after the Add Task row collapses. Every other interaction measured 0 px on
  the base already. Gate: 1973/1973, browser 15/15.
- 2026-09-26 — **Merged `fix/qa-findings`** (`ac6f27e`, `f123a44`, `2dd4619`, `9f1501f` — one commit
  per finding): F1 Escape with a note menu open now closes only the menu (new `note-menu` shortcut
  scope; a draft is no longer threatened by the discard prompt); F2 column drags refresh sortable
  positions after each auto-scroll step (900 px right-drag works, 1600 px unchanged); F3 locked
  section reads retry under the write policy and answer the same `503 storage-locked` (verified
  with a real Windows lock); F4 the Prompt Injection window is placed by its measured height
  (above the anchor when needed, clamped). New adjacent finding: Escape inside the Prompt
  Injection window (no voice) still runs `context.dismiss` and closes the notes pane. Gate:
  1946/1946, browser 15/15.
- 2026-09-26 — **Merged `fix/ai-label-dynamic`** (`2957631`): 74 user-visible "Gemma" strings →
  "AI" across the client and the server messages the client shows verbatim (e.g. "Refine with
  AI", "AI refined this card.", "AI request was rejected. Check the API key and model access.");
  the AI activity panel header and add-task tooltip name the active model ("AI activity · Gemini
  3.5 Flash-Lite") and follow a model switch. A guard test fails on any new user-visible "Gemma"
  literal. No identifier/file/class/key/route renamed (that is the separate Clean Up card). Also
  fixed: every render reset the add-task button to a fixed "Normalize with Gemma". Gate:
  1903/1903, browser 15/15.
- 2026-09-26 — **Merged `fix/prompt-delimiters`** (`657b01a`): every prompt is now ordered tagged
  blocks — `<system_instructions>` (+ a 649-char shared legend), `<task_instructions>`,
  `<formatting_profile>`, `<context>`, `<source_text>`, `<user_request>` last. Prompt Injection used
  to glue saved text and the instruction with a blank line (ambiguous for any note containing blank
  lines); user data was interpolated into rule templates. Vocabulary closing tags inside content
  are escaped (three forged-tag bleed tests). Prompts grew ~18–29%. **Verified with a stubbed model
  only — a live smoke test of add-task, refine and Prompt Injection is recommended before
  release.** Gate: 1884/1884.
- 2026-09-26 — **Merged `fix/voice-helper-tooltips`** (`623b093`): 1–3 phrasing tips inside the
  listening toast, chosen per surface (AI normalize / AI refine / AI note / Prompt Injection), each
  tied by a test to the prompt instruction that backs it — status and "tag it X" phrasing were
  deliberately NOT advertised because no prompt instructs the model to act on them. Never covers a
  Stop control, never takes focus; hide for the session or switch off in Settings › General.
  **Merged `fix/test-walk-race`** (`9354b9c`, mine): the package-boundary test walked the repo
  while other suites deleted their `data-test-*` folders, causing an intermittent ENOENT seen once
  at `--test-concurrency=2`. Gate: 1860/1860, browser 15/15.
- 2026-09-26 — **Merged `fix/theme-contrast`** (`f349cd2`): systematic WCAG audit of all three
  themes (text vs its real background, walked from computed styles). Light/Dark had fallen back
  to hard-coded Erebus colours across the side panel, settings, top bar, notes headings, menus,
  toasts and AI panel; worst: text on tag-coloured cards in Light at 1.10:1 → 15:1, Dark field
  borders 1.8:1 → 3.45:1 (the card's "blending"), In Progress status text 2.31:1 → 6.54:1 in every
  theme. Colours now come from tokens via `--themed-*` aliases whose fallback is the Erebus literal,
  so Erebus renders as before except three failing texts. Owner calls left open: Erebus primary
  buttons (white on #5b9bd5, 2.96:1), Erebus control borders (~1.7:1), the stale "intentionally
  left alone" tag-icon colour. **Housekeeping:** deleted scratch screenshots of Settings › APIs
  taken before 5.7 merged (they could show the misfiled key). Dispatched 5.3 prompt-delimiters,
  4.14 manual-prompt-selection, 5.2 ai-label-dynamic. Gate: 1815/1815, browser 15/15.
- 2026-09-26 — **Merged `fix/logging-levels`** (`2adfae1`): leveled loggers on both sides (server
  `WORKLISTS_LOG_LEVEL`, browser `WorkListsDebug.enable()` / `?debug=1`), debug off by default.
  Removed the per-refresh dump of the whole `/data` payload (twice), full prompt dumps (which
  carried user text), raw model output, request bodies and whole records; every pipeline log line
  names its prompt file (`[prompt:….md]`), carried into trace and failure logs, which redact keys.
  Measured: server start + one `/data` + one AI job 228 lines → 2; browser load + idle refresh 30
  console messages → 0. Resolved conflicts with 2.8 (kept `holdSidePanelLayoutMode`). Gate:
  1784/1784, browser 15/15.
- 2026-09-26 — **Integration QA pass complete** on the combined tree at `40ea134` (then 30 merges):
  42 end-to-end behaviours exercised in Playwright at 1600 px and again at 900 px against fresh data
  copies, with the AI pipeline driven through the real server and a stubbed model — **42/42 PASS,
  no integration regressions**; `/api/integrity` unchanged after every flow (only the 16 legacy
  records); gates 1464/1464, browser 15/15. Failures were cross-checked against a server built
  from `ee8e2de`: four pre-existing defects found, dispatched as 5.8. Not coverable headless: the
  browser's own Ctrl+F highlight (mechanism verified instead), real voice, a real model. A second
  QA pass is planned once the remaining packages land, to cover everything merged after `40ea134`.
- 2026-09-26 — **Merged `fix/column-resize-persist`** (`feac5d0`): drag (or keyboard) resize per
  column, 250–960 px, stored per board on the board record via a validated
  `PATCH /boards/:boardId/column-widths`; column-menu Reset width; board-menu Reset column widths
  behind the app confirm dialog. The handle hangs off a zero-height anchor because making `.column`
  positioned clipped dragged cards. Resolved conflicts with 4.13 (both column-menu actions kept:
  sort → collapse-cards → reset-width → delete) and aligned both suites' order assertions. Agent
  incident: its first probe scripts ran against another agent's server on 4731 (a temp data copy,
  at most a same-order save); no live data involved. **Merged `fix/side-panel-layout-lock`**
  (`3d2cbad`): four measured board jumps (−16, +240, −240, +240/−240 px) → 0; the menu's
  push/overlay choice is made at open and held; card C re-verified. Gate: 1754/1754,
  browser 15/15.
- 2026-09-26 — **Merged `fix/collapsible-board-cards`** (`1a5bff5`): card menu "Collapse Card", column
  menu "Collapse all cards"; two-line heading-aware summary with color, status and checkbox kept;
  editing expands; persistence chosen as per-browser localStorage (view preference, like pinned
  boards / notes-pane width — avoids lastModified bumps and write races; trade-off: no cross-device
  sync); in-place render keeps collapsed nodes. Gate: 1667/1667, browser 15/15.
- 2026-09-26 — **Merged `fix/board-menu-refresh`** (`4f2fb54`): nothing on the refresh path ever
  rebuilt the side panel or pinned bar, and a skipped current-board payload dropped other boards'
  changes entirely; also, non-rendering loads (e.g. opening Move) consumed the gate's "newer data"
  signal so the next refresh skipped a new column. Now the menu is adopted from every payload
  (guarded against older payloads and local pin/rename races) and rebuilt only when its signature
  changes. **Merged `fix/secret-redaction`** (`efbdaac`): `GET /data` now returns models in the
  public shape; a key pasted into `apiKeyEnvVar` is withheld + flagged (Settings warns), refused on
  write, not migrated; redacted `POST /data` round trips keep stored secrets; runtime resolution
  verified unchanged (the misfiled value was never used — calls work via `GEMINI_API_KEY` in
  `.env.local`). **Owner actions:** rotate that key (it has already been served to the browser and
  printed to the browser console by the `/data` refresh log); one note (`dee2d636-…` on card
  `todo-1790184168113`) contains the same key string in its text. Gate: 1632/1632, browser 15/15.
- 2026-09-26 — **Merged `fix/verify-requires-testing`** (`0e31bea`, `5510d09`, `e72af71`, `968aa85`).
  Full verification matrix for the three cards (rebindable shortcuts; the five overlap/scroll
  sub-notes; menu-open shift) — most requirements PASS; four FAILs found and fixed:
  **no modifier chord could ever be captured when rebinding** (the first `Control` keydown was
  rejected and ended capture); conflicts with key-only defaults went undetected (a rebind to
  Ctrl+O silently shadowed the board library); a hard-coded Ctrl+Enter kept submitting Prompt
  Injection after it was rebound; closing the menu within 256 px of the right end jumped the
  columns (scrollLeft read after the browser clamped it). The agent's own `git merge local-fixes`
  was refused by the permission classifier; I did the normal review-and-merge into `local-fixes`
  and aligned one provider assertion with 2.7's voice-aware scopes. Follow-up dispatched as 2.8.
  Owner calls left open: slide duration 240 ms vs Countdowns' 300 ms (same `ease` curve);
  which browser shortcuts (e.g. Ctrl+F) to reserve from rebinding. Gate: 1564/1564, browser 15/15.
- 2026-09-26 — **Merged `fix/code-block-language`** (`ec2b35e`) — **partial**. The fence info string
  (```` ```powershell ````) is the stored language; markdown-kit renders a label or picker only
  when the caller opts in, so its default output is byte-identical (Cairn unaffected; recorded
  package hashes updated deliberately). Picker on board cards, the notes-pane card preview and the
  note fallback renderer; picks save through the same paths as rendered checkboxes, with revert
  and toast on failure. Also fixed: the visual pane was dropping the language and leaking the copy
  button's text into the markdown on round trip. **Not covered: saved notes**, which render on the
  `@cairn/dantalion` surface (`CodeBlockView` in the Dantalion repo) — needs a companion Dantalion
  change (spec in the agent's report, summarised in the final hand-off). Gate: 1545/1545,
  browser 15/15.
- 2026-09-26 — **Merged `fix/voice-toast-lifecycle`** (`280831e`): the listening toast had a 9 s
  timeout and was wiped by any other toast (`showAppToast` cleared the whole region); nothing
  removed it when the session ended; and in the notes pane its Stop counted as an outside click,
  opening the discard dialog instead of stopping. Now a persistent toast (others stack above it)
  bound to the session, removed on Stop/×/Esc/natural end, with a 5 s stop watchdog. Verified with
  a fake SpeechRecognition (the real API does not run headless). Gate: 1520/1520, browser 15/15.
- 2026-09-26 — **Merged `fix/notes-write-race`** (`cd8178d`, `f588b4d`, merges) after the send-back.
  Every server-side readNotes→writeNotes pair (several spanning a multi-second model call) now uses
  atomic DAL note operations (`addNotes` / `updateNote` / `deleteNote`); an AI note rewrite applies
  only if the note still holds the text the model saw (otherwise the existing `source-changed`
  result); note writes now rewrite only `event-notes.json`. Reconciled with 1.4 via a new
  `replaceTodoWithTodos` that re-checks "no notes" and deletes in one serialized operation (a note
  added mid-job used to be deleted with the card). One old test whose premise 1.4 removed was
  replaced by two that assert the new behaviour. Gate: 1499/1499.
- 2026-09-26 — **Interruption:** an API spend limit stopped all six running agents
  (verify-requires-testing, board-menu-refresh, voice-toast-lifecycle, the notes-write-race
  reconcile, integration QA, code-block-language). Worktrees were intact — three had uncommitted
  work in progress, three had not started editing. All six were resumed with their context once
  the limit reset, each told to merge the current `local-fixes` before finishing. Dispatched
  5.7 `secret-redaction` and 2.5 `scroll-jump-bottom-card`.
- 2026-09-26 — **Merged `fix/notes-sticky-header`** (`66fcd20`): card-text header now sticky inside
  its own scroll container; note headers were already sticky but their menu opened ~1000 px off
  screen, faded in transparent, ignored Light/Dark, and a collapse from a pinned header lost the
  note — all fixed. **Merged `fix/integrity-followups`** (`9668118`): `dal.addTodo` refuses unknown
  or missing columns (also closes the AI-job window where a column is deleted during the model
  call); failed optimistic delete / undo / order saves force the refresh past the gate (a card
  whose delete failed used to vanish on the next render); `/tasksOrder` 500s no longer leak paths.
  **Merged `fix/model-capabilities-settings`** (`902dd1b`): informational `webSearch` /
  `imageInput` flags, edited in Settings › APIs, shown as tags. **Security finding logged as 5.7.**
  **Merged `fix/search-result-goto-board`** (`cb227f8`, `62b1b9f`, `b69701e`): "View on Board" on
  search results (board switch, horizontal + vertical reveal, highlight); added a vm stub for the
  board-filter reset introduced by 4.2. **Merged `fix/ai-note-drops-items`** (`11a3c41`): note
  paths join every returned item into the one note instead of keeping item 1. **Merged
  `fix/prompt-injection-refresh-resume`** (`9a211f4`): draft and saved-note Prompt Injection jobs
  resume after reload; voice-in-window Escape stops voice first; resolved a conflict with 2.1 by
  keeping the resume logic and the background-focus gate. **Sent back `fix/notes-write-race`**: its
  atomic note operations conflict semantically with 1.4 (replace now refuses cards with notes;
  child-note paths now go through `addNotes`) — agent reconciling on its branch. **Gate:**
  1464/1464, browser 15/15.
- 2026-09-26 — **Merged `fix/refresh-preserves-focus`** (`6afd005`) — four cards, one mechanism.
  `renderBoard` cleared and rebuilt every column and card on every refresh, `makeTasksSortable`
  blurred the focused element on every render, and AI completions opened the notes pane through
  `closeAllContextWindows` (which closed Settings) and then focused the composer. Now the board is
  updated in place (unchanged cards keep their DOM node, so Ctrl+F highlights and selections
  survive), render never blurs, AI results open the notes pane only when the user is not busy
  (otherwise an "Open notes" toast), scroll snapshots are real (the not-awaited Promise bug), and
  the notes-card scroll happens once per opening instead of on every refresh (the board used to
  jump 9995 px → 0). Measured: `renderBoard` ~350 ms → ~155 ms on the 322-card Erebus board.
  Resolved one textual conflict with the auto-sort helpers and aligned one autoscroll assertion to
  the gated refocus argument. **Merged `fix/notes-collapse-all-shortcut`** (`087cf97`):
  Ctrl+Shift+[ collapses all open notes and restores only those (hand-collapsed notes stay
  collapsed); rebindable. **Merged `fix/board-menu-search`** (`471ca59`): ranked filter under
  All Boards (prefix, word-start, acronym — "ahk" → AutoHotKey), keyboard flow through a
  `board-filter` scope; resolved a scope conflict with `column-create`. **Gate:** 1286/1286,
  browser 15/15.
- 2026-09-26 — **Merged `fix/ai-refine-drops-items`** (`c8533e2`): all three sibling paths were
  real. Automatic refine now keeps the card in place and creates the extra items (it used to
  overwrite the card with item 1 and drop the rest); the replace path only deletes when no item
  repeats the card's text and the card has no notes (it used to delete a card and its notes even
  when the model echoed the original text back); child-note flows keep one card + one note by
  design but now report "N extra generated items were not saved". Undo of an automatic refine also
  removes the cards it created. **Agent incident:** `git stash` is shared across worktrees — this
  agent popped the refresh agent's stash by accident, restored it by SHA within the same minute,
  and the refresh agent's tree was verified intact; the brief now forbids `git stash`. Note-path
  sibling logged as 1.7. **Merged `fix/dnd-scroll-context-windows`** (`beed0bc`): edge zones now
  measured against the visible board, trimmed by an open pane or menu; measured before/after
  (e.g. notes-pane strip: 0 px/s held still → 2170 px/s, normal view unchanged). Gate:
  1203/1203, browser 15/15.
- 2026-09-26 — **Merged `fix/dnd-blocked-search-toast`** (`a64583f`): the drag starts during search
  but `renderSearchResults` turns `connectWith` off, so the drop snapped back silently. The stop
  handler now decides synchronously (before any await) and shows the toast with "Clear search"
  instead of the card's "Undo" (nothing moved). The agent's note that a search-mode drag overwrote
  column order with only the visible cards is already fixed server-side by 1.3. Suite 1155/1155.
- 2026-09-26 — **Merged `fix/prompt-cards-mode-dropdown`** (`a5c099c`): one "Cards" select
  (Single / Multiple / AI Discretion) over the unchanged booleans. Every stored pair displays as the
  mode `gemmaNormalize.js` actually enforces (a test runs the real precedence function across all
  9 pairs). Note for the owner: saving a prompt whose stored pair was non-canonical rewrites it to
  the canonical pair — same card count, slightly different wording sent to the model. Adjacent,
  not fixed: Sub-child notes = Yes silently overrides Cards = Multiple. Suite 1139/1139.
- 2026-09-26 — **Merged `fix/card-move-integrity`** (`608a89f`) — the most consequential fix so far.
  The DAL's lock admitted every caller at once (measured 5 of 5 inside together), and ~35 DAL
  writers read then write as two steps, so concurrent requests silently overwrote each other
  (8 concurrent moves → 7 lost; a card created during a move vanished). Now a FIFO mutex, every
  async DAL export serialized as one operation, `columnId` changes move the id between column lists
  in one write (unknown column → 404), stale/partial `PUT /tasksOrder` and `PUT /boards/:id`
  orders are merged instead of stored verbatim (search-mode reorder used to truncate every column
  to its matching cards), `PUT /columns` no longer resurrects deleted columns, and external
  `readDB`→`writeDB` pairs are conflict-checked (409, nothing written). New read-only
  `GET /api/integrity`. **Live data audit (on a copy): 16 legacy broken records — 15 cards whose
  column does not list them (7 in Countdowns › Ideas) and 1 card, "Animal List"
  (`todo-1781022868863-39d1c7c5`), pointing at a column deleted before July. Not repaired — owner
  decision.** Resolved two `server.js` conflicts with 1.2 so storage failures are answered first.
  **Merged `fix/stale-test-repair`** (`89aba92`): all three carried failures were stale assertions
  after deliberate changes (`06b78be`, `72c31b1`); two now run the shipped functions under `vm`.
  **The suite is fully green for the first time since June.** **Merged
  `fix/column-delete-flash`** (`4b3c521`): the card's original flash was already gone (`9680e35`),
  but a stale background refresh could still resurrect a deleted column; now removed locally
  first with a tracker that strips it from older payloads, and restored on failure. **Merged
  `fix/status-reorder-settings`** (`acf9f42`): `PUT /statuses/order`, Move up/down, 409 for a stale
  id set. **Merged `fix/column-create-cancel`** (`1359f26`, `3ea34b0`) after the send-back: the
  re-render case is told apart from a real click with a one-microtask MutationObserver check.
  **Gate on `local-fixes` after 18 merges:** `npm run lint` pass · 1112 tests, **1112 pass, 0 fail**
  · `npm run test:browser` 15/15. New packages logged: 1.5, 1.6, 2.7.
- 2026-09-26 — **Merged `fix/default-tag-rename-persist`** (`c534144`). Server side was already
  correct; the client's `rebuildGlobalTagsFromState` re-merged the hard-coded built-in list (and
  stale localStorage caches) after the server records loaded, minting a phantom
  `primary-tag-backend-2`. Server records now own the inventory once loaded; the built-ins only seed
  when neither a server answer nor a cache exists. Reproduced and verified in the browser for
  rename and delete.
- 2026-09-26 — **Merged `fix/dnd-placeholder-line`** (`f1ccbd4`). The "line" in scrolling columns
  was never a second style: the jQuery UI placeholder was a fixed 40px box, and an overflowing
  flex column shrank it to its 2px border. `height: 0` gives every column (short, empty, scrolling)
  that same line; drop index verified in all three column types plus auto-scroll.
- 2026-09-26 — **Merged `fix/write-failure-feedback`** (`09949cd`): backoff retry for OneDrive lock
  codes (7 attempts, 100 ms doubling to a 2 s cap, ~5.1 s total — the same window as before, but a
  short lock now costs 100 ms instead of 1 s); `writeDB` holds the lock until every section settles
  (`allSettled`); a controlled `503 storage-locked` / `500 storage-write-failed` body on every
  write route (no paths leaked, including the old `/tasksOrder` echo); client toast "… was not
  saved" with Reload. Real Windows file lock used for browser proof. The "blocked" secondary tag
  from the card was deliberately **not** stored (it would write to the failing store). Agent
  incident: it stopped a `node server.js` on port 4617 it believed was its own; the owning agent
  restarted it 40 s later and every agent reported green runs — brief tightened so agents only
  stop PIDs they started. **Merged `fix/auto-sort-on-change`** (`4ba525a`): completion, Undo,
  column Reset, batch, and AI add/refine now feed the existing reapply; also fixed a redraw gap
  where the saved order already matched but the screen was stale. Resolved the expected conflict
  with the reveal calls (order: reload → re-sort → reveal) and aligned two source-contract tests
  to that order in `7b081a8`. **Merged `fix/test-data-isolation`** (`bbf7557`): three suites
  (`gemma-normalize`, `openapi`, `checklist-format`) now use a temp `DATA_DIR`; a guard test fails
  any suite that loads dal before assigning `DATA_DIR`. **Sent back `fix/column-create-cancel`**:
  blur-to-cancel also fires when a re-render detaches the section, which would wipe a typed title
  whenever an AI job completes. **Gate on `local-fixes`:** 974 tests, 971 pass, 3 known failures.
- 2026-09-26 — **Merged `fix/move-menu-alpha-order`** (`5ba8cfb`, `ba36f63`, `03186d8`) after the
  send-back: natural-order destinations, card Move now opens on the card's own board, column Move
  placement shows real titles. **Gate on `local-fixes` after 7 merges:** `npm run lint` pass ·
  `node --test --test-concurrency=4 "tests/*.test.js"` 906 tests, 903 pass, 3 known failures.
- 2026-09-26 — **Merged `fix/ai-multi-card-persist`** (`3b6d11d`). Root cause: commit `06b78be`
  ("General Updates") forced `card_count: 1` on card and task-draft Prompt Injection, which both
  made the multi-card branch unreachable and told the model "Return exactly 1 card"; the single
  path then kept only `taskEntries[0]`. Reproduced with a stubbed model (server log shows 3 items
  parsed, 1 persisted). Fix keeps LD-002 (no *existing* card or note other than the target is
  modified): item 1 rewrites the target in place (id, notes, tags kept), items 2..n are new cards in
  the same column, Undo deletes them and reopens the prompt. Draft injection with several items
  creates each card and clears the draft only if unedited. **Behaviour change the owner should
  know:** card Prompt Injection can now split into several cards when the classifier reads the
  request that way — before, it never could. Sibling defects logged as 1.4; the agent's finding
  that `dal.addTodo` / `deleteTodo` do read-modify-write outside the lock was forwarded to the
  card-move agent.
- 2026-09-26 — **Merged `fix/new-task-autoscroll`** (`66b6c95`). Root cause traced to `02798f3`
  (2026-05-24), which moved AI add-task creation into a server job: the browser only reloads and
  never ran `addTodo`'s reveal. Typed entry and duplicate were verified still working. The
  suspected `uiUpdated` scroll restore was ruled out as the cause (it undoes the reveal for one
  frame, then the reveal's own retry wins) — forwarded to the refresh agent together with the
  finding that several `saveScrollPositions()` calls are not awaited. Forwarded "AI-created cards
  skip sort reapply" to the auto-sort agent.
- 2026-09-26 — **Merged `fix/settings-scrollbar-style`** (`f6afbdd`): every Settings scroll area and
  textarea adopts the filter-menu scrollbar declarations and joins the three themed scrollbar lists;
  measured 15px default gutters → 10px thin in Erebus / Light / Dark. **Merged
  `fix/toast-stack-overflow`** (`e403a12`): the overflowing surface was the AI activity panel, not
  the shared toast (which never stacks). Region bounded top and bottom, panel scrolls, scroll kept
  across the per-poll rebuild, jumps to top only when a new job arrives. **Merged
  `fix/tag-window-second-tag-edit`** (`4560e6a`): the card's original bug (pencil click closed the
  window) was already fixed by `58a0293` — reproduced on the pre-fix code to confirm; the agent
  found and fixed the remaining defect in the same row (Escape closed the whole window instead of
  cancelling the rename). New finding logged as 3.11.
- 2026-09-26 — **Merged `fix/search-bar-right-gap`** (`69d992f`). Cause: the collapsed search input
  carried the width transition, so on cancel the icon returned instantly (a `display` toggle cannot
  animate) beside a still-wide fading input. Transition moved to the expanded rule; opening still
  animates. Reviewed: diff (CSS only, no `!important`), before/after frames on Erebus and light
  themes, 6 new tests. **Sent back `fix/move-menu-alpha-order`**: the sort is right, but it moved
  the dialog's arbitrary default board from "Daily Start" to "Agents" — asked for the card's own
  board as the default, plus the agent's own finding that column Move → Placement shows
  "After Untitled column" for other boards (`columns.find` limited to the current board).
- 2026-09-26 — Sweep finding: fresh worktrees fail 20 `gemma-normalize` tests with `ENOENT` because
  `data/*.json` is gitignored. Worktrees are now seeded with a copy of the live data. Checked the
  live data was not written by the baseline `npm test` run (last write 2026-09-25 19:32). Added
  5.5 `test-data-isolation` so the suite stops depending on the default data directory.
- 2026-09-26 — `main` fast-forwarded `049d73f..ee8e2de` and pushed to `origin/main`. Pre-push
  gates on that tree: audit pass (4 moderate, below threshold) · lint pass on tracked files ·
  `npm test` 807 tests, 804 pass, 3 known failures · `npm run test:browser` 15 / 15.
  `local-fixes` created at `ee8e2de`.
