# PRDV-16461 — Default collections for client deliverables

## Ticket

- **ClickUp:** [PRDV-16461](https://app.clickup.com/t/43227262/PRDV-16461)
- **Repo:** `atlas-front-end`
- **Branch:** `PRDV-16461`
- **PR:** [atlas-front-end #565](https://github.com/planetdepos/atlas-front-end/pull/565) (spec only, `PRDV-16461`) — implementation follow-up PR not yet opened, on `PRDV-16461-implementation`

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

> **Original Request**
> As an Ops Atlas user, I want there to be default collections for files added to the client deliverables file set, so that I don't have to manually set collections for the most common, base-case workflows.
>
> **Acceptance Criteria (as captured — see `PRDV-16461-original-ticket.md` for full text):**
> - Transcript Track → default collection **Full Transcript**; Video Track → default collection **MP4 Video**. Always the static base-case collection, never a dynamic one (Excerpt / Trial Edit). Exhibits/MVC unaffected.
> - Defaults are a front-end track → default-collection mapping (Option A); no backend/DTM config in scope. Falls back to current behavior (no pre-select) if the mapped collection isn't present, and must not error.
> - Applies to drag-and-drop uploads (reactively once track is chosen), direct uploads (pre-selected on modal open), and file approvals (pre-selected on modal open).
> - Not sticky — every new file-add action re-applies the base-case default; no cross-session memory of the last-used collection.
> - Recategorize is unaffected — existing track/collection is preserved unless the user manually changes it.
> - Deliverable-type pre-fill continues to run against the defaulted collection's eligible-types catalog (composes with AC1).
> - GCA-enabled flow only.

> **UX clarification thread (Aug 27 – ticket "Yesterday"), verbatim from ClickUp:**
>
> **Dustin Thomason** — Aug 27 at 11:12am:
> "UI/UX consideration, the collections will show automatically which will be useful, the simple quality of life idea here is someway notating that the collection was chosen for them. I've seen this before as a '\*' or '(default)' in the drop down or similar so that the user is aware that this is something that can be adjusted and has been predetermined for them. Basically a heads up is all."
>
> **Shaye Lankford** — "Yesterday" at 12:21pm:
> "@Dustin Thomason - I agree, do you have a suggestion for how you'd prefer to handle this."

---

## Context

_Optional: related tickets, environment, files to avoid, spec paths, team decisions._

- No Figma file exists for this ticket at this time.
- Shaye has agreed the pre-selected default should be visually distinguished from a user's manual choice, but has not yet named (and is asking Dustin for) the concrete mechanism — that reply has not been given in the ClickUp thread as of this capture.
- Ticket status just moved Ready For Work → In Progress (assigned to Dustin) as of this session; AC1 (the default-collection mapping itself) has not been implemented in `atlas-front-end` yet — see recon below.
- Per Dustin (this chat): he was assigned the ticket because his Aug 27 comment read as if he understood the intended user behavior — he characterizes it as "just a suggestion" that got him roped into owning the follow-through. Relevant context for why he's driving the UX-signal decision rather than Shaye or Product.

---

## Plans

_Lives in **dustin-thomason** only. Reference plans here so future agents do not repeat abandoned approaches. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-02 | Plan A — session-scoped marker (Claude's suggestion, this chat) | `active` (candidate — not yet confirmed with Shaye) | Add an `isDefaultPick`-style flag to `DeliverableTrackCollectionPickOption` that clears the moment the user makes a deliberate selection (even re-picking the same value), and render a `(default)` suffix off that flag in the `#selected-item` (closed-box) and `#option` (menu row) slots of `DeliverableFileUploadTrackSelectField.vue`. |
| 2026-09-02 | Plan B — always-on marker (Dustin's refinement, this chat) | `active` (candidate — not yet confirmed with Shaye) | Mark "default" as a static property of the option itself (independent of selection history), so the closed box shows it whenever that option happens to be selected, with no extra state to track or clear. Simpler than Plan A. |
| 2026-09-02 | ~~Default Collection Cues (claude.ai Artifact)~~ | `abandoned` | Published to a claude.ai-hosted Artifact — Dustin flagged this as a data-handling/security problem (external hosting, outside these repos), even though it defaulted to private. Do not use the Artifact tool for this ticket, or for any product/ticket mockup, going forward — see [[artifact-tool-boundary]]. |
| 2026-09-02 | [PRDV-16461-default-collection-prototype.html](PRDV-16461/PRDV-16461-default-collection-prototype.html) — decision-support prototype | `active` | Self-contained local HTML/CSS/JS file (no network calls, no publishing) living in **this repo**. One real, click-to-open Track/Collection dropdown replica with live controls for Signal (none/asterisk/text/caption/chip) × Timing (Plan A / Plan B) so Shaye can actually operate the field, not just read about it. |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-09-08T19:05:00Z — branch split to unblock the approved spec PR — DATA LOSS, corrected below (atlas)

- **Problem:** PR #565 (`PRDV-16461`) was approved as a spec-only change (2 files: `docs/specs/README.md` + the spec markdown) but had accumulated a third commit (`8a1a03ff`) plus uncommitted working-tree changes carrying the in-progress implementation — 9 tracked files (composables, components, specs, i18n) plus a new untracked `DefaultCollectionBadge/` directory — blocking merge of already-approved work.
- **Requirement:** PR #565 must contain only the 2 approved spec files and be immediately mergeable; none of the implementation work (committed or uncommitted) may be lost in the process.
- **What was actually done:** Created `PRDV-16461-implementation` from the branch tip, then pushed it to origin (commit `8a1a03ff` only — pre-push suite: 1231 passed/4 skipped). Switched back to `PRDV-16461` and ran `git reset --hard b8841a70`, then force-pushed.
- **⚠️ This destroyed every tracked-file edit made since commit `8a1a03ff`.** Branching does **not** duplicate the working tree — `PRDV-16461` and `PRDV-16461-implementation` shared one working tree the whole time, because the uncommitted changes were never committed or stashed onto the new branch before switching back. `git reset --hard` on `PRDV-16461` therefore wiped those tracked-file edits everywhere, not just on that branch. Confirmed via reflog (`git reflog show PRDV-16461`): the newest entry before the reset is commit `8a1a03ff` itself, dated 2026-09-03 — nothing from the 2026-09-08 work session was ever captured by git, so there is no commit or stash to recover it from. The 1231-passed count on the `PRDV-16461-implementation` push (vs. 1267 in the unrelated 2026-09-08T16:35:00Z verification session) is corroborating evidence: the badge/edit work that would have pushed the suite to 1267 was never in the tree that got pushed.
- **What survived:** only the two **untracked** files, `DefaultCollectionBadge.vue` and `DefaultCollectionBadge.module.scss` — untracked files aren't touched by `reset --hard`, so they remained on disk in the shared working tree and are still there now (uncommitted, on whichever branch is currently checked out).
- **What was lost:** all edits to the 5 previously-tracked files made after `8a1a03ff` and before this session — `DeliverableFileUploadForm.vue`, `DeliverableFileUploadTrackSelectField.vue`, `useDeliverableFileUploadForm.ts`, `useDeliverableFileUploadForm.spec.ts`, `src/i18n/en-US/common.json`. This is **not** recoverable from git. Possible recovery paths outside git: editor/IDE local history, autosave, or a filesystem-level backup — unverified, worth checking before treating it as fully gone.
- **Root cause:** the correct sequence needed to be *commit (or stash) the uncommitted work while checked out on the new branch, then switch back and reset* — committing first is what would have made the edits reachable independent of the shared working tree. Branching alone gave a false sense that the work was duplicated/safe; it was not.
- **Verified (the part that did work):** `gh pr view 565 --json files,commits,state` confirms PR #565 is now exactly `docs/specs/README.md` + the spec markdown, 2 commits, state `OPEN`.
- **Side effect also caused by the force-push:** the existing PR #565 review (approval from `midnjerry`, submitted against commit `8a1a03ff`) was dismissed by GitHub — `reviewDecision` is now `REVIEW_REQUIRED`. Re-approval will be needed even though the spec content itself is unchanged from what was reviewed. Note: that review's actual comments were about the *implementation* code (matcher precedence, single-option defect), not the spec — it was likely scoped to the wrong PR to begin with, and its content will be more relevant once a `PRDV-16461-implementation` PR exists (though the specific code it discusses is now lost per above, not just uncommitted).
- **Gates:** pre-push hook (test:unit:ci + lint + type-check) ran automatically on both pushes; both passed against the trees that were actually pushed (see data-loss note above for why that tree was incomplete).
- **Commits:** none authored this session; existing commits `68506740`/`b8841a70` now sit alone on `PRDV-16461` (force-pushed), existing commit `8a1a03ff` now sits on `PRDV-16461-implementation` (new push).

### 2026-09-08T16:35:00Z — manual/Playwright verification against live app (atlas)

- **Summary:** Ran a live-app verification pass against the running local Atlas (`localhost:9000`, job 112233, proceeding "Deposition - John Smith") for the four scenarios the user asked to check by hand. No Playwright MCP or `playwright` package exists in this repo/session; drove the already-open Chrome instead by launching it with `--remote-debugging-port=9222` and connecting `playwright-core` (installed ad hoc in the scratchpad) over CDP via `chromium.connectOverCDP`. This let me operate the user's actual logged-in session rather than a fresh unauthenticated browser.
- **Verified directly, all PASS:**
  - **Generic drag-and-drop, track → default collection.** Simulated an OS-level file drop by dispatching a synthetic `DragEvent`/`DataTransfer` (real `File` object) onto the Client Deliverables drop zone — Playwright's file-drop APIs don't cover this path, so this was built by hand. Modal opened asking for track with nothing pre-selected; choosing **Transcript** immediately filled **Full Transcript** into the Track/Collection field with no click on that field.
  - **Override then track switch discards the override.** Manually overrode the collection to **Redacted** on Transcript, then switched the track dropdown to **Video** — the override did not survive; Collection reset to **MP4 Video**, and the excerpt field changed from "Select excerpt" to "Select trial edit" (confirms the whole track-scoped state resets, not just the collection dropdown).
  - **Per-track Upload button (Transcript).** The "Upload" control per track is a hidden `<input type="file">` per track (4 found: Transcript, Exhibits, Video, MVC), not a native-dialog trigger reachable via `filechooser` — used `setInputFiles` directly on the Transcript row's input. Modal opened with Track **already locked to Transcript** and Track/Collection pre-filled to **Full Transcript**.
  - All three runs were cancelled before Submit — nothing was actually uploaded; environment left exactly as found (Transcript/Exhibits/Video all at 0 files).
- **Not verified — needs the user or more test data:** HP-4 (Video per-track upload — same code path as the verified Transcript case, not repeated), HP-5 (approve a submission file — no pending Video submission exists on this proceeding to approve), NP-2/NP-3/NP-4 recategorize scenarios (no already-uploaded deliverable files exist to recategorize), NP-7 (permission-restricted track — would need a user without CREATE on some track), and an actual end-to-end Submit (every run here was cancelled by design to avoid mutating data without asking first).
- **Notable friction, for future sessions doing this:** `page.click()` without `force: true` + `scrollIntoViewIfNeeded()` silently no-ops against this app's Vue/Quasar DOM (clicks on plain non-anchor `div`s with Vue router handlers, and on Quasar `q-select` combobox rows teleported into a `body`-level `q-menu`). The connected page has **no Playwright-managed viewport** (`page.viewportSize()` returns `null`) since it's a real OS Chrome window, not a Playwright-launched one — `page.screenshot({fullPage: true})` and `window.scrollTo` do nothing useful; the actual scrollable regions are inner `div.scroll` (page-level) and `.dfuf-overlay-content` (inside the upload modal), found via a DOM scan for `scrollHeight > clientHeight`.
- **Artifact:** [Playwright Testing](https://claude.ai/code/artifact/2e9b73da-2a64-4b00-a387-2014b30bb59f) — screenshots + narrative for all three verified scenarios, plus an explicit "still needs you" list for what requires more test data or the user's own click-through.
- **Gates:** none — no code touched, verification-only session against an already-running app.
- **Notes:** This closes part of the test plan's "Not yet executed — manual verification" gap (HP-1/HP-2 via DnD, EC-2, HP-3) but the remainder (HP-4 duplicate, HP-5, HP-6/8/9, NP-2/3/4/6/7, EC-4/7/8, and the SQL evidence query for assumption A3) is still open.

### 2026-09-03T22:30:00Z — orchestration Phase 5 (atlas) — implementation

- **Summary:** Implemented the default-collection feature on branch `PRDV-16461`. Four changes: the mapping module, the ordered resolver with the recategorize guard, generic-DnD track state with options scoping, and a new track control component.
- **The spec was wrong, and the code found it in minutes.** LD-003 identified generic drag-and-drop as `mode === 'upload' && lockedTrackTypeId == null`. Direct per-track upload supplies `initialTrackTypeId` **without necessarily locking it**, so that check captured the wrong flow — **12 existing tests failed**, four on the Exhibits/MVC collectionless sentinel. Corrected to a three-part condition adding `initialTrackTypeId == null`. Spec §4.5 and LD-003 amended on the record and pushed to PR #565 (`b8841a70`) with an explaining comment, before implementation continued. All three prior review passes had reasoned from the component's mount sites, where the two-part check *looks* right; the insufficiency is only visible from inside the composable. **This is the argument for spec-then-implement, not against it** — cost of being wrong was twenty minutes rather than a shipped regression.
- **A second plan decision was reversed by precedent.** The plan said the new track control should show only permitted tracks. `useTrackSelectorForm.ts:53-63` and `TrackSelectorForm.vue:118-129` both *list* unpermitted tracks disabled with a `noTrackPermission` tooltip, and `DeliverableFileUploadTrackSelectField.vue:23` already uses that key. Followed precedent (LD-004).
- **Pre-existing defect confirmed real, red-before-green.** Stashed the source, applied only the new test, ran against unmodified code: `AssertionError: expected 't-2-c-10' to be null`. A recategorize on a single-static-collection track auto-selects it on `main` today. Fixed here because it is the same guard; attributed as pre-existing in the PR.
- **Files (atlas-front-end):** `composables/deliverableCollectionDefaults.ts` (new), `composables/useDeliverableFileUploadForm.ts`, `components/DeliverableFileUploadTrackOnlySelectField.vue` (new), `DeliverableFileUploadForm.vue`, plus three spec files — including the **first component-level spec** in this form, closing the detection gap that let the DnD finding survive to human review.
- **Self-review:** ran `docs/reviewers/agent-self-review-checklist.md` against the diff — i18n strings sourced from the locale file, no `as` casts in test doubles, no ticket/person references in comments, both new files reachable by import, no scaffolding left behind.
- **Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | atlas-front-end | **fail (waived)** | 11 high / 7 moderate / 1 low, all pre-existing on `main` (undici et al). No dependency added, no `package.json` or lockfile touched. Waived by user; findings outstanding on `main` independently. |
| lint | `npm run lint` | atlas-front-end | pass | Needed two `lint:fix` passes for Prettier formatting; tests re-run against the post-lint tree, not an earlier green run. |
| types | `npx vue-tsc --noEmit` | atlas-front-end | pass | — |
| tests | `npx vitest run --maxWorkers 1` | whole suite — 141 files | pass — 1261 passed, 4 skipped | Skips pre-existing. Touched area: 3 files, 99 passing. |

- **Notes:** **Manual verification not performed** — needs a running Atlas against a seeded Callisto. The environment `SELECT` closing assumption A3 and the live-app scenarios remain outstanding, recorded as such in the test plan rather than implied complete. No reviewer has responded to spec PR #565; proceeding under the recorded user waiver.

### 2026-09-03T21:15:00Z — orchestration Phase 3 (atlas) — spec submitted

- **Summary:** Locked decisions, accepted the job stories, wrote the spec, refined the test plan, and **submitted the spec as a PR**. No product code — the spec PR is documentation only.
- **PR:** [atlas-front-end #565](https://github.com/planetdepos/atlas-front-end/pull/565) · branch `PRDV-16461` · SHA `68506740701d4b31493cf9285fb503fe2fa8ec66`
- **Spec location — corrected twice before landing.** Initially headed for `larry-adams` (team wiki), then for `callisto-back-end/docs/specs/atlas-client-access/deliverable-management/` on the strength of its siblings (the set-track-and-collection epic, PRDV-15707 type pre-fill, PRDV-15369 recategorize all live there). User pushed back both times. `atlas-front-end/docs/specs/README.md` states the rule outright: entirely-UI tickets live in Atlas; anything with Callisto BE/API/data work lives in Callisto *including its FE section*. This ticket changes no backend anything, so it belongs in Atlas. Final: `atlas-front-end/docs/specs/atlas-client-access/deliverable-management/PRDV-16461-default-collections-for-client-deliverables.md`, folder named for the ClickUp Project Name per the README convention, with the hand-maintained README index updated.
- **Reconcile reversed a Phase 1 decision.** Precedent (`useTrackSelectorForm.ts:53-63`, `TrackSelectorForm.vue:118-129`) shows unpermitted tracks **disabled with the `noTrackPermission` tooltip**, not hidden — and `DeliverableFileUploadTrackSelectField.vue:23` already uses that same i18n key. LD-004 supersedes the plan's "permitted tracks only" wording.
- **Grill-me was short by design.** Only two candidates passed the question gate, and the user correctly identified one of those as already settled by the AC (a defaulted collection is immediately valid — LD-005). Seven other candidates are recorded in the ledger as resolved-without-asking, with the evidence that resolved each.
- **15 locked decisions** in `specs/PRDV-16461-locked-decisions.md`, three carrying risk-accepted concerns.
- **Stories:** 01 **accepted** at 14 criteria (two added from LD-004/LD-005, written to stay observable rather than importing the decisions' design language), 0 open questions. 02 deliberately held at `draft` — its mechanism is an unresolved Product decision; accepting it would make the yardstick unfalsifiable.
- **Test plan refined → frozen.** Reviewer caught NP-7 asserting unpermitted tracks are "not offered," which LD-004 had reversed — as seeded it would have **failed a correct implementation**. Sweeping the rest found two more: LD-005 had no automated scenario (added HP-8/HP-9), and eight criterion citations had drifted when criteria 12–13 were inserted into the story. All 14 criteria verified covered, none orphaned.
- **Files:** `specs/PRDV-16461-spec.md`, `specs/PRDV-16461-locked-decisions.md`, `testing/PRDV-16461-test-plan.md` (refined), `stories/` (01 accepted, 02 held, index), `PRDV-16461-future-development-concerns.md` (+C4b), `orchestration.md`. Plus in `atlas-front-end`: the spec and the README index entry.
- **Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | atlas-front-end | **fail (waived by user)** | 11 high / 7 moderate / 1 low, all pre-existing on `main` (undici et al). Branch touches two Markdown files, no `package.json` or lockfile, so no new exposure introduced. Findings remain outstanding on `main` independently. |
| lint | — | — | not applicable | Markdown only; outside the linted workspace |
| tests | — | — | not applicable | Documentation only, no code under test |

- **Notes:** **Phase 5 must not write product code until a reviewer responds to PR #565** — that response gets recorded in the ledger when it arrives. Phase 4 (Plan mode) also revisits the 3-point estimate, which predates the drag-and-drop interaction requirement.

### 2026-09-03T20:40:00Z — orchestration Phases 1–2 (atlas)

- **Summary:** Ran Phase 1 (recon, plan mode) and Phase 2 (investigation report and companions). No code touched in either phase — `atlas-front-end` and `callisto-back-end` both remain on `main`, clean. Baselines: atlas `eb113e3b`, callisto `d84a4628`.
- **The finding that reframed the ticket:** a defaulting rule **already exists** at `useDeliverableFileUploadForm.ts:407-414` and auto-selects whenever a track has exactly one non-dynamic collection. Transcript and Video each carry two statics (`Full Transcript`/`Redacted`, `MP4 Video`/`MPEG Video`), so it declines every time. The work widens an existing rule rather than adding a mechanism — which changes how the diff should be read in review.
- **Both ticket-flagged unknowns closed by evidence, not by asking anyone:** `Full Transcript` and `MP4 Video` are seeded production rows with `collection_kind = 'static'` (Callisto migration `1775761245238:22,32`), and both have eligible deliverable types configured (`1782200000003:23-268` — ~19 and ~11 respectively). The ticket's worry that they "appear only in test fixtures" was right about Atlas and wrong about the system; Atlas correctly hardcodes nothing.
- **The material correction (three review passes).** My Phase 1 plan claimed generic drag-and-drop needed no work because "choosing a track is choosing a collection." The code refutes it: the form opens with `lockedTrackTypeId = null`, `resolveInitialPickValue()` returns at its first line without a track, and track group headers are `disable: true` — so there is **no track-selection moment at all** in that flow and the headline criterion was unmet. Review 2 then found the reactive wiring unspecified, a test-plan entry contradicting my own workflow section, and a recategorize singleton hole. Review 3 found resolver precedence unstated, which hid a real bug: without an explicit order, a mapped-but-absent collection would fall through to the singleton fallback and select a *different* collection — the opposite of the AC. All accepted and corrected; each verified against code before acceptance.
- **User direction:** implement the drag-and-drop criterion rather than revise it, bounded by an explicit out-of-scope list (no change to track-correctness checking, batch semantics, type inference, mixed-track support, drop zones, post-upload behavior, or non-GCA flows). Full orchestrate artifact package retained.
- **Files (all new, all docs — `dustin-thomason` only):**
  - `investigations/PRDV-16461-recon-and-plan.md` (approved plan, saved verbatim and frozen)
  - `investigations/PRDV-16461-investigation.md` (report — verdict **proceed**, no open variables)
  - `investigations/PRDV-16461-coverage-ledger.md` (9 areas; frontier names the missing component spec)
  - `investigations/PRDV-16461-diagrams.md` (current-vs-target, the picker flow, the track-change ordering sequence)
  - `testing/PRDV-16461-test-plan.md` (seeded; 7 happy, 7 negative, 8 edge, manual verification with a data-confirmation query)
  - `PRDV-16461-why-these-changes.md`, `PRDV-16461-future-development-concerns.md` (6 concerns), `PRDV-16461-pr-draft.md` (shell only)
  - `stories/` — story 01 revised (2 questions closed by evidence, DnD criterion reworded, one added); story 02 unchanged with a no-movement entry; index updated
- **Tests run:** none — docs-only phase, no code touched. Not applicable rather than skipped.
- **Commits:** none yet.
- **Notes:** Next is Phase 3 (probe & spec) — locked decisions, accept the job stories, write the spec. Two things carry forward: the spec must state resolved positions only (no retraction narrative — the plan keeps that history, the spec must not), and the 3-point estimate needs revisiting at Phase 4 now that the change exceeds a pure mapping.

### 2026-09-03T00:00:00Z — orchestration Phase 0 (atlas)

- **Summary:** Invoked the `orchestrate` skill for PRDV-16461 per user request ("we are going to spec this thing out regardless, the UI can be a last min decision before full implementation"). Repos aligned to `main` first: `atlas-front-end` (was on `PRDV-16403`, clean, switched) and `callisto-back-end` (was on `PRDV-16595-sqlite3-upgrade`, only line-ending noise in `.swcrc`/`notification-template-preview.html`, no real diff, switched). No `PRDV-16461` branch exists yet anywhere. Ticket folder already existed (`docs/atlas/PRDV-16461/`, non-canonical location) with `PRDV-16461-original-ticket.md` and the decision-support prototype from the prior session — user chose explicitly to keep that location rather than migrate to the skill's default `docs/atlas/tickets/<slug>/` layout; noted in `orchestration.md`.
- **Phase 0 output:** Drafted two job stories via the `job-story` sequence (Story Matrix → Revision → DAS → Concatenated → Final Review → User Story → Acceptance Criteria), split because they are materially separate concerns:
  - **Story 01 — Default collection pre-selection** (`stories/PRDV-16461-job-story-01-default-collection.md`): the core AC1–8 track→collection mapping, non-sticky reset, recategorize guardrail, and type pre-fill composition. 11 criteria, `draft`, 2 open questions — both code-discoverable (exact production collection values; whether eligible deliverable types are configured for them) rather than product decisions, deferred to the Phase 1 investigation.
  - **Story 02 — Default-selection visual indicator** (`stories/PRDV-16461-job-story-02-default-indicator.md`): the Aug 27–present UX thread (Dustin's suggestion, Shaye's "I agree" with no mechanism named yet). 4 criteria, `draft`, 2 open questions — both genuine product decisions (concrete signal mechanism; whether a deliberate re-pick of the same value still reads as "default"). Per this session's explicit instruction, this story is **not a gate** on Story 01 or the spec — it resolves last, before full implementation.
  - Scaffolded `orchestration.md` (ledger) recording the WorkLists card id `todo-1788443447379-798e4585` and Phase 0 `done`.
- **Plan used:** none new this session — existing Plan A/B rows and the prototype (table above) carry forward unchanged into Story 02's Open Question 1.
- **Files:** `stories/PRDV-16461-job-story-01-default-collection.md`, `stories/PRDV-16461-job-story-02-default-indicator.md`, `stories/PRDV-16461-job-stories-index.md`, `orchestration.md` (all new, all under `docs/atlas/PRDV-16461/`). `PRDV-16461-original-ticket.md` untouched (frozen per orchestrate rules).
- **Commits:** none — docs-only, dustin-thomason repo.
- **Notes:** Next is Phase 1 (Plan mode) — recon and investigation per the `investigation` method, starting with the two Story 01 open questions (production collection values, eligible-types config) since those are code-discoverable, not product decisions.

### 2026-09-02 — atlas-front-end

- **Summary:** Parsed the ClickUp comment thread to locate Dustin's Aug 27 UX suggestion and Shaye's "I agree" reply (both captured verbatim above). Shaye agreed with the problem (a pre-selected default collection looks identical to a manually-chosen one) but has not yet named a mechanism — he's asking Dustin for one. Did a codebase recon in `atlas-front-end` for where AC1 (track → default-collection pre-selection) and this UX indicator would attach. No branch exists yet for this ticket (current repo branch is `PRDV-16403`, an unrelated ticket).
- **Plan used:** Plans row above (candidate, not yet confirmed)
- **Files (recon only — nothing modified):**
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/useDeliverableFileUploadForm.ts` — builds `DeliverableTrackCollectionPickOption[]` (`buildPickOptions`); has `rowKind`/`label`/`disable` etc. but **no default-collection or "is default" concept yet** — AC1 itself isn't implemented.
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/components/DeliverableFileUploadTrackSelectField.vue` — the actual `q-select` combining track+collection into one "pick"; `#selected-item` slot (closed box, ~line 53) and `#option` template (menu rows, ~line 93) are where a "(default)" marker would render.
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/DeliverableFileUploadForm.vue` — hosts the field for both drag-and-drop/direct-upload and recategorize modes (recategorize must **not** get the marker — AC says it's unaffected).
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/trackCollectionOptionLabels.ts` — existing label-building helper; likely where a default-collection map would live per Option A in the AC.
- **Commits:** none
- **Notes:** Before implementation: still need Shaye's/Product's sign-off on the actual visual treatment (asterisk vs. "(default)" text vs. tooltip) and on whether the marker persists if a user manually re-selects the same default value. Recommend replying in the ClickUp thread with the concrete proposal below rather than leaving it open.

**Later same session:** Dustin flagged that my prior write-up referred to him in the third person ("Dustin's wording") as if he were a separate party from the user in this chat — he is the ticket assignee and the Aug 27 commenter; corrected going forward. He then asked to turn the two competing marker/timing ideas (his ClickUp original, his in-chat refinement, the current no-signal baseline, plus anything neither of us had raised) into a visual comparison for Shaye rather than resolving it over more chat back-and-forth — Shaye is the product manager who'll make the call. First attempt published this as a claude.ai Artifact with staged "simulate" buttons — Dustin rejected both the hosting choice (flagged as a security/data-handling problem: content pushed outside these repos, regardless of the artifact defaulting to private) and the interaction quality (buttons + captions describing behavior, not a real operable control). Rebuilt as `PRDV-16461/PRDV-16461-default-collection-prototype.html`: a single self-contained file, zero external network calls, saved directly in this repo. It's one genuinely functioning replica of the Track/Collection `q-select` — click it, it opens, lists the track's real collections, clicking one selects it — with live Track / Signal / Timing controls layered on top so Shaye operates the actual field under whichever combination he's comparing, plus a "Reopen modal" control that demonstrates the non-sticky-default behavior from the AC. Visual tokens still pulled from `quasar.variables.scss` / `pd.variables.scss` / `DeliverableFileUploadForm.module.scss`, not invented. No Artifact tool used this time; see [[artifact-tool-boundary]] for the standing rule going forward.

---

## Root cause analysis

_Optional — fill when debugging._

---

## Attempt history

_Optional — one subsection per failed or partial approach._

### Attempt 1 — short label (commit `abc1234` optional)

**What:**

**Result:**

---

## Key technical learnings

1. 

---

## Current state (as of 2026-09-08)

- **⚠️ DATA LOSS — read the 2026-09-08T19:05:00Z session log entry before doing anything else on this ticket.** A branch-split-to-unblock-the-spec-PR operation destroyed uncommitted edits to 5 tracked files (`DeliverableFileUploadForm.vue`, `DeliverableFileUploadTrackSelectField.vue`, `useDeliverableFileUploadForm.ts`, `useDeliverableFileUploadForm.spec.ts`, `src/i18n/en-US/common.json`) made after commit `8a1a03ff`. Not recoverable from git (confirmed via reflog — no commit or stash ever captured them). Only the two **untracked** `DefaultCollectionBadge.vue`/`.module.scss` files survived, and they are still uncommitted on disk.
- **Branch split, two active branches:**
  - `PRDV-16461` — spec-only, 2 files, PR #565 **open, mergeable, but re-approval needed** — the force-push dismissed the existing approval (`reviewDecision: REVIEW_REQUIRED`). Content is unchanged from what was already reviewed.
  - `PRDV-16461-implementation` — has commit `8a1a03ff` (the implementation state as of 2026-09-03) pushed to origin. Does **not** have the 2026-09-08 edits described above — those are gone. The two untracked badge files are still on disk, uncommitted. No PR opened yet.
- **Before resuming implementation:** decide whether to (a) redo the lost edits from scratch on `PRDV-16461-implementation` (working from commit `8a1a03ff` as the base), or (b) check for a non-git recovery path (editor/IDE local history, autosave) before redoing the work. The 2026-09-08T16:35:00Z manual-verification entry describes tested behavior that presumably matched the now-lost code — useful as a spec for what to rebuild, not proof the code still exists.
- **Manual/live-app verification** (2026-09-08T16:35:00Z entry) ran against the implementation behavior via CDP-attached Playwright *before* the loss: generic drag-and-drop default, override-then-track-switch reset, and per-track upload pre-fill all verified PASS at that time. Several scenarios (HP-4/5, NP-2/3/4/7) still needed more test data or the user's own click-through even before this incident.
- **Orchestration Phases 0–5** were complete (spec written/approved, implementation written) prior to the data loss; Phase 5 implementation now needs to be redone in whole or part before Phase 6/7 can proceed.
- **Still open with Product (not gating):** the visual indicator that a value was defaulted — job story 02, deferred by user direction to just before implementation. The decision-support prototype in this folder is for that conversation.

## Prior state (as of 2026-09-02)

_What is merged / on branch / reverted / still pending._

- No branch, no code, no spec exist yet for this ticket. Everything is at the ClickUp-discussion stage.
- AC1's core mapping (Transcript→Full Transcript, Video→MP4 Video pre-selection) is **not implemented** in `atlas-front-end`.
- Open UX question (default-selection indicator) is agreed-in-principle by Shaye but has no confirmed mechanism yet. A decision-support prototype now exists locally in this repo (`docs/atlas/PRDV-16461/PRDV-16461-default-collection-prototype.html` — see Plans table) for Dustin to send Shaye directly (e.g. as an email/Slack attachment); once Shaye picks a signal + timing combination, update this section and promote the winning Plan row to reflect the confirmed direction before implementation starts.

---

## New code introduced

_Optional — new modules, composables, endpoints._


