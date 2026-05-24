# WorkLists App Changelog

## Purpose
Track implementation sessions for the WorkLists project so cross-session context stays current.

## Scope
Feature work, bug fixes, behavior changes, and verification runs completed in the WorkLists codebase.

## Session log

### 2026-05-22
- Summary: Implemented Move Card from one column to another through the card action menu, using a column-move-style dialog and an atomic backend move endpoint.
- Files/areas:
  - `dal.js`
  - `server.js`
  - `openapi.js`
  - `public/apiService.js`
  - `public/cardActions.js`
  - `public/todolist2.js`
  - `public/todoliststyles2.css`
  - `.prettierignore`
  - `tests/api.test.js`
  - `tests/openapi.test.js`
  - `tests/card-actions.test.js`
  - `tests/card-move-ui.test.js`
- User-visible impact:
  - Card action menu now supports `Move` as an active action.
  - Move opens a destination/placement dialog with the same interaction pattern and layout family as column move.
  - Moving a card updates source and destination column ordering while preserving the card’s details and tags.
- Safety/data integrity:
  - Created backup before integration work: `data-backups/20260522-000757/`.
- Verification run:
  - `npm test`
  - `npm run lint:fix`
  - `npm run lint`
  - `npm test` (post-format verification)
- API docs check:
  - Updated OpenAPI contract for `POST /todos/{id}/move` with request/response schemas and coverage.

### 2026-05-22
- Summary: Consolidated card-level copy and delete controls into a single hover-revealed ellipsis menu and added a visible Move placeholder for upcoming board-to-board card moves.
- Files/areas:
  - `public/cardActions.js`
  - `public/todolist2.js`
  - `public/todoliststyles2.css`
  - `public/taskClipboard.js`
  - `public/index.html`
  - `tests/card-actions.test.js`
  - `tests/task-clipboard.test.js`
- User-visible impact:
  - Card actions are now available from one consistent ellipsis menu on each card.
  - Copy and Delete remain functional from the new menu.
  - Move is visible as a non-destructive placeholder labeled as coming soon.
  - Hover-based action discovery is preserved.
- Verification run:
  - `npm test`
  - `npm run lint`
- API docs check:
  - N/A - no HTTP API contract change in this session.

### 2026-05-22
- Summary: Implemented deferred post-edit reordering for tag-based sorts so cards do not move while the user is still making tag selections.
- Files/areas:
  - `public/todolist2.js`
  - `tests/secondary-tags.test.js`
- User-visible impact:
  - Tag-based sorting now waits until tag editing is finished (Done, outside click, Escape, chooser close).
  - New untagged items remain at the bottom when active tag sort is applied.
  - Repeated tag edits reapply sort consistently after completion.
- Verification run:
  - `node --test tests/secondary-tags.test.js tests/column-sort.test.js tests/edit-session.test.js`
  - `npm run lint`
- API docs check:
  - N/A - no HTTP API contract change in this session.

## Current state
- Card actions use a single ellipsis menu per card with active Copy, Move, and Delete actions.
- Card move is implemented with an atomic backend move endpoint (`POST /todos/:id/move`) and column-style destination/placement dialog flow.
- Deferred tag-sort flush logic remains implemented and wired to tag chooser completion events.
- Active sort reapply remains enforced after add/create for sorted columns.
- Full regression and formatting checks are passing.
