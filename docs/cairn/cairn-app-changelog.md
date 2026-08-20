# Cairn App — General Changelog

## Purpose

Running changelog for Cairn, a markdown-vault UI intended for integration into the WorkLists app (UI, UX, architecture decisions, and testing).

---

## Scope

- **App:** `Cairn`
- **Primary workspace:** `C:\Users\dktho\OneDrive\PDProjects\Cairn`
- **Log location:** `C:\dustin-thomason\docs\cairn\cairn-app-changelog.md`
- **Integration target:** `WorkLists` (`C:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`)

---

## Current state

**Phase:** POC 1 — look and feel only. Not integrated into WorkLists yet.

- A runnable zero-build prototype exists at `PDProjects/Cairn`. Open `index.html`; no install, no server.
- **Nothing writes to disk.** Sample-vault edits persist to `localStorage` (`cairn-poc-v1`); the real-folder path via the File System Access API is read-only.
- Markdown rendering is delegated to a **verbatim copy** of `WorkLists/public/markdownRenderer.js` at `vendor/markdown-renderer.js`, so render output and the task-checkbox round-trip are proven for the integration target, not just for the POC.
- Palette is lifted from `WorkLists/public/todoliststyles2.css` rather than newly chosen, per the WorkLists changelog constraint against introducing a second dominant palette.
- Open decisions are listed under **Intentionally unresolved** in `PDProjects/Cairn/README.md`. The one that changes existing content: the vendored renderer turns single newlines into hard `<br>` breaks, which is correct for card notes and an open question for full documents.

**Next:** judge the look and feel against the five questions at the end of the POC README, then decide the vault-adapter seam (File System Access vs. an HTTP adapter on the existing Express server) before any write path is built.

---

## Plans

| Date | Plan | Status | Approach |
| --- | --- | --- | --- |
| 2026-08-20 | V1 scope agreed in-session (chat) | `active` | Adapter seam + tree + preview/source toggle + save + checkbox write-back + favorites + quick open. Explicitly defers full-text search, live/hybrid preview, wikilinks, and graph view. |
| 2026-08-20 | POC 1 — look and feel (this session) | `implemented` | Zero-build HTML/CSS/JS prototype mirroring the shape of `Argus-POC-v1-2026-08-12`; embedded sample vault, no disk writes. |

---

## Session log

_Newest first. Add one entry per working session or merge-worthy update._

### 2026-08-20T00:00:00Z — POC 1: markdown vault shell

- **Summary:** Created the Cairn project and a runnable look-and-feel POC for a markdown vault that reads like OneNote and behaves like VS Code.
- **Problem:** Reading and ticking off markdown notes currently means opening Cursor. There was no evidence about whether a browser-hosted vault UI could feel good enough to live inside WorkLists, and no basis for deciding the harder questions (file access, editor choice, write-back) without that evidence.
- **Requirement:** A vault must be browsable as a tree, readable in preview by default with source one keystroke away, and a checkbox ticked in the preview must rewrite exactly one line of markdown source. It must be judgeable without installing anything, and it must not be able to damage real notes.
- **Solution:** A zero-build prototype at `PDProjects/Cairn` following the shape of the Argus POC (`index.html` + `styles.css` + `app.js`, seeded content, open the file to run). Markdown rendering is a verbatim vendored copy of the WorkLists renderer, so `updateTaskCheckboxMarkdown()` supplies the single-line splice rather than a new implementation. The real-folder path is read-only by design; every save target is browser storage.
- **Code name:** Cairn — a stacked trail marker left for whoever comes next. Same mineral family as Obsidian without imitating it; no collision with an existing PDProjects folder or a known markdown tool (unlike Slate → Slate.js, Quartz → Obsidian Quartz).
- **Files/areas:**
  - `PDProjects/Cairn/index.html`, `styles.css`, `app.js` — shell, visual language, behavior
  - `PDProjects/Cairn/vendor/markdown-renderer.js` — verbatim copy of `WorkLists/public/markdownRenderer.js`
  - `PDProjects/Cairn/sample-vault/**/*.md` + `sample-vault.js` + `tools/build-sample-vault.mjs` — sample content on disk plus its generated embedded copy (`fetch()` is blocked on `file://`)
  - `PDProjects/Cairn/README.md` — run instructions, what it proves, intentionally unresolved
- **User-visible impact:** OneNote-style section tabs from top-level folders; keyboard-navigable explorer tree; tab strip with dirty markers; Preview / Split / Source modes; checkbox-to-source rewrite; favorites; `Ctrl+P` fuzzy quick open; outline rail with an `Alt+↑/↓` heading pointer; resizable sidebar; session restore.
- **Defects found and fixed during runtime verification** (all root-cause fixes, no overrides or tuned constants):
  1. Split mode stacked the panes vertically. The `::before` divider is the first grid item in box order, so leaving the preview pane to auto-place pushed it onto a second grid row. Fixed by placing all three split children explicitly.
  2. Vertical rhythm was counted twice — the renderer emits a `markdown-blank-line` spacer per source blank line, and CSS block margins were also firing. Collapsed the spacer to zero so block margins are the single owner of rhythm in a full document.
  3. The empty Favorites group stayed visible: `.sidebar-group { display: flex }` outranks the `[hidden]` attribute's default `display: none`. Added `.sidebar-group[hidden] { display: none }`.
  4. Nested lists carried the top-level list's block margins, adding a paragraph gap per indent level. Scoped `li > ul, li > ol` to the list-item margin; item pitch is now uniform at 26–27px across depths.
- **Finding recorded, not fixed:** the vendored renderer joins paragraph lines with `<br>`, so soft-wrapped prose renders with hard breaks where standard markdown would join them. Left verbatim to preserve parity with WorkLists and documented as an open decision; `sample-vault/Notes/markdown-kitchen-sink.md` demonstrates it.
- **Tests run:** No unit harness exists in this repo (see **Tooling gates**). Verified by driving the real page in headless Chromium via Playwright resolved from the WorkLists workspace. Confirmed: exactly one source line changes when a checkbox is ticked (`- [ ]` → `- [x]` at line 9, total line count unchanged); split panes share a row and span the full width; favorites, edited text, view mode, and active tab all survive reload; all 7 sample files render; no page or console errors; zero horizontal overflow at 1520px and 960px.
- **Tests added/updated:** None — blocked. This POC has no test harness and no `package.json`; adding the first one would mean scaffolding a runner unrelated to the look-and-feel question this POC exists to answer. Residual risk: no regression guard on the checkbox round-trip or the tree/keyboard behavior. Smallest follow-up that unlocks coverage: a `package.json` with Playwright plus the assertions already written for this session's verification.
- **Regression impact:** Isolated — new top-level project folder. No file in `WorkLists` or any other repo was modified; the WorkLists renderer was read and copied, never edited (`WorkLists/public/markdownRenderer.js` is byte-identical to `Cairn/vendor/markdown-renderer.js`).
- **API docs:** Not relevant — no HTTP surface in this POC. No route, method, DTO, status, or auth decorator exists to change; the prototype makes no network calls.
- **Tooling gates:** `audit` — not applicable: no `package.json` at `PDProjects` root or in `Cairn`. `lint` — no lint script in this project; formatted with the WorkLists Prettier binary and config against `index.html`, `styles.css`, `app.js`, `README.md`, `tools/`, and `sample-vault/**/*.md`; `prettier --check .` reports clean. `vendor/` and the generated `sample-vault.js` are `.prettierignore`d so parity diffs against WorkLists stay readable.
- **Conflicts / exceptions:** WorkLists board not updated — no card id was supplied and `worklists-card-sync` forbids searching for a card by title or ticket id. The WorkLists server was reachable (`GET localhost:3010/openapi.json` → 200), so this is a missing-input stop, not the server-down skip. Waiting on the card id, or on approval plus a template pointer to create one.
