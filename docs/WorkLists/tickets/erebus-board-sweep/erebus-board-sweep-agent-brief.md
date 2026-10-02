# Erebus board sweep — implementing-agent brief

Every implementing agent in the sweep reads this before touching code. The orchestrator's prompt
gives you: your **work package slug**, your **worktree path**, your **branch**, and the **card(s)**
you are fixing with their text and sub-notes verbatim. The plan is
[`erebus-board-sweep-plan.md`](./erebus-board-sweep-plan.md).

## The app in one paragraph

WorkLists is a local Kanban app: Node/Express backend (`server.js`, `dal.js` data access over
per-section JSON files in `data/`, `openapi.js` contract, `gemmaNormalize.js` + `prompts/` for the
AI pipeline, `fileRepository.js`) and a vanilla-JS frontend in `public/` (`todolist2.js` is the
~22k-line main script; `todoliststyles2.css` the main stylesheet; smaller modules such as
`cardActions.js`, `columnActions.js`, `columnSort.js`, `shortcutRegistry.js`, `boardScroll.js`,
`taskDragScrollOwnership.js`). Markdown editing is `packages/markdown-kit` (served at
`/markdown-kit/`) plus the external `@cairn/dantalion` package. Tests are `node:test` files in
`tests/`, mostly source-contract tests plus HTTP tests against `server.js` and one Playwright
smoke test (`tests/browser-notes-smoke.js`).

## Hard boundaries

- **Work only inside your worktree.** Never `cd` into, edit, or run git write commands against the
  main checkout at `C:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`. Never check
  out, commit to, merge into, or push `main` or `local-fixes`. Never push anything.
- **The live server on `http://localhost:3010` is read-only to you.** `GET` is fine (for example
  `GET /todos/<card-id>` and `GET /api/notes?eventId=<card-id>` to re-read your card). No `POST`,
  `PUT`, `PATCH` or `DELETE` to it, ever. Do not stop or restart it.
- **Never point a server at the live data directory.** For browser checks, copy
  `C:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists\data\*.json` into a fresh temp
  directory and start your worktree's server against the copy:
  `PORT=<4500-4999> DATA_DIR=<temp copy> WORKLISTS_TMP_DIR=<temp>/tmp node server.js`
  (PowerShell: set `$env:PORT` etc. first). Stop that server when you are done. Use 4500+:
  `npm run test:browser` picks a random port in 3400–4399 and will silently load your server's
  data if it collides with it.
- **Never use `git stash`.** The stash list is shared by every worktree of the repository, so a
  `stash pop` can apply another agent's work into your tree. To capture "before" evidence, check
  out the base commit into a scratch folder (`git worktree add` is not yours to run either — use
  `git archive <base> | tar -x -C <temp>` or `git show <base>:<path>`) instead.
- **Only stop processes you started.** Record the PID of every server you launch and stop exactly
  those. Many agents run servers in parallel; a `node server.js` you did not start belongs to
  someone else even if it is on "your" port.
- Your worktree's `data/` folder already holds a **copy** of the live data (gitignored). Some
  suites (`tests/gemma-normalize.test.js`) read the default data directory and fail with `ENOENT`
  without it. Leave it in place; never copy anything back to the main checkout.
- `node_modules` in your worktree is a set of junctions into the main checkout. **Do not run
  `npm install`, `npm ci`, or anything that writes into `node_modules`.** If you believe you need a
  new dependency, stop and say so in your report instead.

## How to work

1. Re-read your card(s) and every sub-note. The sub-notes are the specification. Frame your work as
   **Problem → Requirement → Solution** before writing code.
2. Find the real cause before changing anything. For layout / CSS / interaction defects, follow
   `browser-loop-guardrails`: fix the responsible rule, not the symptom; no `!important` or
   heavier-selector band-aids; every numeric constant you introduce carries a comment naming what it
   represents; stop after three failed observe-fix cycles and report the competing hypotheses
   instead of guessing again.
3. When the card leaves a detail open, resolve it from the app's existing patterns (how sibling
   features already behave) and record the decision in your report. Only stop for a genuine product
   decision the code cannot answer — and even then, ship the clearly-intended part.
4. Keep the diff minimal and local. **Other agents are editing the same large files in parallel**
   and their branches merge after yours:
   - Put new CSS next to the existing rules for the same component, not at the end of the file.
   - Put new tests in a **new** file `tests/<your-slug>.test.js` unless an existing test must change
     because behaviour it asserts changed on purpose.
   - Do not reformat, re-indent, or rename code you are not changing.
   - Do not "fix" adjacent issues outside your card; list them in your report.
5. Tests are part of the change: happy path, failure path, and edge cases where risk exists. Where
   the repo's pattern for a surface is a source-contract test, follow it — but a UI behaviour change
   also gets a real-browser check (below).

## Gates (run from your worktree root)

| Gate | Command | Pass condition |
| --- | --- | --- |
| lint | `npm run lint` | exit 0 (the pre-commit hook runs it too) |
| targeted tests | `node --test tests/<file>.test.js` | while iterating |
| full tests | `node --test --test-concurrency=2 "tests/*.test.js"` | **zero failures.** (Branches cut before `local-fixes` commit `2605abf` still carry 3 stale failures — `keeps all card actions in one menu definition`, `keeps AI note reveal targets…`, `wires Ctrl+Shift+Backslash…` — which are repaired on `local-fixes`; on such a branch, those 3 and only those are acceptable.) |
| browser smoke | `npm run test:browser` | 15/15 — run it when you touched anything in `public/` |

Run the full suite **once**, at the end, after your last edit (`--test-concurrency=2` keeps
several agents from saturating the machine at once). Report the final run, not an earlier one.

## Real-browser evidence (UI changes)

Use Playwright (`require("playwright")`, Chromium is installed) against your own server on a spare
port with a copied data directory. Reproduce the defect **before** your fix when you can, confirm it
is gone **after**, and save screenshots to a temp folder. Give the absolute paths in your report.
Write throwaway Playwright scripts to a temp folder, not into the repo, unless you are adding a
durable scenario to `tests/browser-notes-smoke.js` on purpose.

## Committing

- Commit on your branch only. Subject: 5–7 words, imperative (`Fix column delete flash`), then a
  body with Problem / Requirement / Solution in a few lines, then a blank line and
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- One commit is ideal; several are fine if each is coherent. Never amend a commit you did not make.

## Your final report (this is all the orchestrator sees)

1. **Outcome** — done / partially done / not done, in one line.
2. **Problem → Requirement → Solution** for what you changed.
3. **Root cause** — what was actually wrong, with `file:line` references.
4. **Files changed** and the commit SHA(s) on your branch.
5. **Tests added/updated** — file names and what they assert.
6. **Gate table** — exact command, scope, result for lint / full tests / browser smoke.
7. **Browser evidence** — before/after screenshot paths and what each shows.
8. **Decisions you made** where the card was open, and why.
9. **Not done / residual risk / adjacent issues noticed** — be plain about anything you did not
   finish or could not verify.
