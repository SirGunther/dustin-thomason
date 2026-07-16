# Investigation Report: WorkLists prompt injection for note refinement

> What this is: the delivered Phase 1 investigation findings for adding prompt injection to WorkLists card and note refinement.
> What this is not: an implementation approval or a final product spec. Phase 3 still needs to lock the prompt target, context-selection, and API shape before code changes.

## Metadata
- **Status:** done
- **Disposition:** proceed with conditions
- **Date:** 2026-07-16
- **Owner:** Codex for investigation artifact; Dustin for product decisions marked open
- **Location:** `C:\dustin-thomason\docs\WorkLists\tickets\prompt-injection-note-refinement\investigations\prompt-injection-note-refinement-investigation.md`
- **Ticket:** WorkLists - Implement Prompt Injection for Note Refinement
- **Domain:** software
- **References / evidence:**
  - `C:\dustin-thomason\agents\skills\investigation\SKILL.md`
  - `C:\dustin-thomason\agents\docs\problem-check.md`
  - `C:\dustin-thomason\agents\docs\investigation-question-coverage.md`
  - `C:\dustin-thomason\agents\docs\investigation-software-gaps.md`
  - `C:\dustin-thomason\agents\docs\investigation-report.md`
  - `C:\dustin-thomason\docs\WorkLists\worklists-app-changelog.md`
  - `C:\dustin-thomason\docs\WorkLists\features\ai\worklists-ai-refinement-integration.md`
  - `public/index.html`, `public/todolist2.js`, `public/apiService.js`, `server.js`, `gemmaNormalize.js`, `openapi.js`
  - `tests/gemma-ui.test.js`, `tests/shortcut-registry.test.js`, `tests/context-windows.test.js`

---

## 0. Verdict
Proceed with conditions. The request is viable, but the current framing combines a UI affordance, context-routing contract, AI job-shape question, and possible note hierarchy change. The strongest path is to treat prompt injection as a transient notes-pane context window that separates the user's instruction from saved card/note text, reuses the existing flat card-attached notes model for v1, and routes structured context into the existing model-backed note create/refine pipeline. This is not yet a production approval: Phase 3 must lock the meaning of sub-note, the context-selection rules, the shortcut, and whether the server contract extends existing `add-note` / `refine-note` jobs or adds a dedicated injection job type.

- **Strongest path:** build a transient floating injection surface in the notes pane, backed by structured AI payloads and prompt-folder templates, with v1 output creating/refining flat notes attached to the active card.
- **Not yet proven / not approved:** nested note persistence, full-thread truncation rules, the exact job schema, the final shortcut chord, model-quality thresholds, and final-review parity for injected note jobs.

## 1. Problem class
- **Class the request assumed:** UI affordance gap: add a designated Prompt Injection field or floating context window in the notes pane.
- **Confirmed class:** AI context-routing and note-workflow control gap inside an existing notes pane and background AI job system.
- **Reframed?** yes, from **new notes-pane field** to **transient instruction plus structured context routing**, triggered in Step 4 by evidence that current notes are flat `eventId` records, existing AI note create/refine already exist, and current create/refine paths do not distinguish user instruction from saved content.
- **What the confirmed class implies:** the implementation should avoid a persistence-first design. The solution must separate transient prompt text from durable card/note content, explicitly decide which saved context is sent to AI, and keep AI-facing instructions in prompt files rather than embedding new instruction copy in UI or server infrastructure.

## 2. Problem statement
- **Named instances:** Dustin using WorkLists notes-pane AI workflows while refining card/note threads. This is directionally confirmed by the request and WorkLists-specific docs, but there is no separate ClickUp link, customer transcript, or dated production incident in evidence.
- **One sentence:** A WorkLists user cannot run a transient, context-aware AI instruction from the notes pane to refine card/note content or create a follow-up note without first putting that instruction into saved card or note text.
- **Distinct problems:**
  - Transient prompt-entry UI: no designated injection field/window separate from saved content.
  - Context routing: no locked rule for sending the parent card, all notes, or selected segments.
  - Sub-note semantics: WorkLists currently stores flat card-attached notes, while the request says sub-notes from parent cards and existing sub-notes.
  - AI job contract: current jobs accept `input` or `sourceText`, not a structured instruction/context/target object.
  - Shortcut and voice access: existing editor shortcuts and voice capture exist, but prompt injection needs its own scoped behavior.
  - Undo behavior: current undo restores saved card/note content; requested undo also restores the original injection prompt text to the transient window.
- **Urgency:** before Phase 3 Probe and Spec for this feature, starting from this Phase 1 artifact on 2026-07-16. No external release date is currently evidenced.
- **Wedge:** add one reusable transient injection flow for the notes pane that targets existing flat card-attached note creation/refinement and can later grow into richer context selection or nested note persistence if Phase 3 proves that need.

### Problem Check

## In brief
The request asks for prompt injection in WorkLists notes so a user can create or refine notes with context without changing the parent card content. The discussion is currently solving both a UX problem and an AI contract problem, with unresolved terms around sub-notes and thread context.

# The question
---
### Asked
|  |  |
|---|---|
| **finding** | Add prompt injection for note refinement in WorkLists. |
| **evidence** | "Implement Prompt Injection for Note Refinement" |

### Answered
|  |  |
|---|---|
| **finding** | Define a transient notes-pane AI workflow with context selection. |
| **drift** | "prompt injection field" -> "floating context window plus AI routing" |
| **evidence** | "Floating Context Window Implementation Vision" |

### Should-ask
|  |  |
|---|---|
| **finding** | What saved object should AI change or create, and what context may it use? |
| **why** | It decides whether this is UI-only, API-contract work, or note-model work. |

# Flags
---
### Conflation
|  |  |
|---|---|
| **finding** | Prompt entry, sub-note hierarchy, context selection, undo, voice, and job contract are treated as one feature. |
| **consequence** | Solving the floating window alone will not decide note persistence or AI payload semantics. |
| **evidence** | "Creation of sub-notes" / "include the entire thread" |

### Thin
|  |  |
|---|---|
| **finding** | Sub-note and entire thread are not defined against current WorkLists data. |
| **evidence** | "parent card + all sub-notes" |

### Off
|  |  |
|---|---|
| **finding** | Persistence is listed while prompt injections are described as transient. |
| **consequence** | The spec must separate persisted AI outputs from non-persisted prompt text. |
| **evidence** | "Transient Nature" / "Persistence: Maintain parity" |

## 3. The contract
### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| The investigation cites changelog, existing AI artifact, and source evidence. | covered | Evidence is listed in Metadata and Section 5. |
| Problem Check is run and recorded. | covered | Section 2 includes Asked, Answered, Should-ask, Conflation, Thin, and Off. |
| The report reconciles each required investigation doc. | covered | Section 11 includes a reconciliation checklist. |
| The feature has a transient prompt surface separate from saved card/note text. | needs-proof | Phase 3 spec must define the UI surface and implementation must prove no prompt draft is persisted. |
| Injection can create a note from top-level card context. | needs-proof | Implementation tests must cover parent card -> new note using selected context. |
| Injection can create a note from existing saved-note context. | gap | Phase 3 must decide whether this is a flat follow-up card note or a real child-of-note. |
| Injection can refine existing card text or note text without stale source races. | needs-proof | Save-first/source-changed behavior must mirror current refine-card/refine-note guards. |
| Context selection supports full thread and specific segments. | gap | Phase 3 must define selectable segments, ordering, token/size limits, and labels. |
| Voice input, Enter line breaks, and Ctrl/Cmd+Shift+Enter submit are supported. | needs-proof | Shortcut and voice-session tests must cover the injection surface. |
| Undo restores the prior saved result and can reopen/restore the injection prompt text. | gap | Current undo restores saved card/note content; prompt-window restore is new. |
| AI-facing copy remains in prompt files/templates. | documented | Changelog and AI artifact establish this as current convention. Implementation must keep it. |
| Notes pane context windows and menus do not close unexpectedly. | needs-proof | Context-window tests and browser smoke must cover the new surface. |

### Non-goals / out of scope
- No app code implementation in Phase 1.
- No public API or OpenAPI schema change in Phase 1.
- No migration to nested note persistence unless Phase 3 explicitly proves sub-note means note-of-note.
- No third verifier/final-review model pass unless separately scoped.
- No rewrite of existing card/note AI create/refine flows.
- No broad module ingestion beyond the WorkLists notes, AI, shortcut, prompt, and context-window surfaces.

## 4. What changed since the request was created
- **Shifted from:** `Add a Prompt Injection field/interface` -> **to:** `Add a transient instruction surface plus structured context routing for notes-pane AI workflows`.
- **What that buys us:** it protects parent card and note data from prompt pollution, keeps v1 aligned with current flat notes, and makes the hard choices explicit before code changes.
- **What it still needs to prove:** whether sub-note means a flat card note, an output grouped under a saved note in UI only, or a persisted parent-note relationship; whether full-thread context needs truncation; and whether the server contract should extend existing job types or add a dedicated injection job.

## 5. Why it exists
- **Origin traced to:** the WorkLists notes pane already supports card text editing, saved notes, AI note creation, AI note refinement, card refinement, voice input, and shortcuts, but the existing flows use saved text as the AI input. There is no separate transient instruction/context object.
- **Evidence:**
  - Changelog checklist requires AI note creation and note refinement parity with card-level AI actions: `worklists-app-changelog.md:35`.
  - Notes are stored as `event-notes` with `noteId`, `eventId`, `text`, and timestamps; `/api/notes?eventId=<cardId>` drives card notes: `worklists-app-changelog.md:3187`, `:3207`, `openapi.js:2502-2512`.
  - Existing AI note create/refine actions were added through the shared model-backed job flow: `worklists-app-changelog.md:2906`, `:2920`, `public/todolist2.js:5357`, `:5402`.
  - The current AI artifact says note create and note refine are two-call background jobs: `worklists-ai-refinement-integration.md:38-40`.
  - The same artifact says note refine currently lacks the same `finalReview` wrapper as card refinement: `worklists-ai-refinement-integration.md:117`, `:126`.
  - Current server jobs support `add-task`, `refine-card`, `add-note`, and `refine-note`: `server.js:1324`, `openapi.js:1603`, `openapi.js:1961`.
  - `createGemmaNotePayload(eventId, text)` creates a flat note record, and generated child notes are still attached to a parent card id: `server.js:2008`, `:2024`, `:2095`, `:2159`.
  - Changelog explicitly says AI note creation/refinement remains a single-note flow and will not create nested notes: `worklists-app-changelog.md:2286`.
  - Prompt instructions were centralized into files and remaining directive copy moved into prompt-folder templates: `worklists-app-changelog.md:3428`, `:3431`, `:2434`, and `worklists-ai-refinement-integration.md:20`, `:143`.
  - Shortcut handling is centralized: notes AI runs through `notes.aiRun` and global AI fallback; voice uses `voice.global.start`: `public/todolist2.js:2766`, `:2816`, `tests/shortcut-registry.test.js:852`, `:904`.
  - Context windows already have known notes-pane/menu risks; the changelog documents notes-pane card menu dismissal fixes and shared context-window exclusivity: `worklists-app-changelog.md:87-102`, `:3691`.
  - Full test runs currently carry a known unrelated `tests/gemma-ui.test.js:417` voice-session shortcut-scope failure: `worklists-app-changelog.md:51`, `:99`, `:157`.
- **Class re-check:** held with reframing. The root cause is not missing persistence or a missing model; it is missing separation between transient instruction text, saved source text, selected context, and the target AI action.

### Software lens findings
- **Contract / source-of-truth alignment:**
  - Note persistence authority: `openapi.js` Note schema plus `server.js:createGemmaNotePayload` and `/api/notes` routes.
  - AI job authority: `server.js:createGemmaJobDefinition`, `/api/gemma-normalize/jobs`, and OpenAPI job schemas.
  - Prompt-copy authority: prompt-folder templates and `gemmaNormalize.js:createGemmaNormalizationPrompt` composition.
  - Shortcut authority: `ShortcutRegistry` / `ShortcutController` registrations in `public/todolist2.js`.
- **Affected surfaces:** notes-pane card preview actions, saved-note actions, add-note composer, header ellipsis/menu dismissal, shortcut scopes, voice-session fallback, pending AI job tracking, AI job request/status schemas, prompt templates, undo toasts, browser smoke coverage.
- **Protected neighbors:** existing `AI note` button behavior, notes create/save, inline note refine, card refine, generated child-note behavior, Copy/Copy All/Edit Notes/Delete/Move/Duplicate menu actions, markdown editor behavior, unsaved draft guards, and note-pane outside dismissal.
- **Detection gap:** existing tests prove current AI note create/refine wiring, but no test can currently assert transient prompt injection because no injection surface or structured injection payload exists. The first implementation should add red tests before adding behavior.

## 6. Alternatives considered
| Alternative | Rejected because |
|-------------|------------------|
| Keep using the add-note composer as the prompt field | It persists or transforms the draft into note content and does not separate instruction from context. |
| Add a persisted Prompt Injection field to cards or notes | It contradicts the transient requirement and risks prompt pollution in durable card/note data. |
| Build nested note persistence immediately | Current WorkLists notes are flat `eventId` records, and changelog evidence says AI note create/refine remains a single-note flow. Nested persistence is larger than the v1 wedge. |
| Concatenate full thread context client-side into existing `input` / `sourceText` | It is the fastest path, but hides target/context boundaries from the server, prompt trace, OpenAPI, and tests. Use only as a temporary spike, not the durable contract. |
| Add a dedicated prompt-injection job type immediately | It may be the cleanest long-term shape, but Phase 3 must first decide output modes and whether existing `add-note` / `refine-note` can carry structured injection fields with less churn. |
| Add a third verifier/final-review model pass now | The AI artifact states finalReview is deterministic shaping today and a third pass is future work needing its own prompt file and trace stage. |

## 7. Solution & stress-test
- **Proposed solution:** for v1, add a transient floating injection window adjacent to the active notes-pane field/card/note, submit a structured instruction plus selected context into the existing AI job pipeline, and create/refine flat card-attached notes unless Phase 3 explicitly requires nested persistence.
- **Solves the confirmed class?** yes, if the implementation keeps instruction, source text, context, and target action separate through UI, client job payload, server validation, prompt assembly, trace, completion, and undo.
- **Acceptance-criteria coverage:** UI and shortcut criteria need implementation proof; data-model and API criteria are intentionally gated behind Phase 3; prompt-file convention is documented and should be treated as a hard constraint.
- **Scale:** full-thread context can grow with note count and note length. Phase 3 must set context length limits, segment ordering, and visible truncation/failure behavior before implementation.
- **Generalization:** do not build a generic all-app prompt-injection framework first. Build a notes-pane-specific controller with clear target/context abstractions so other surfaces can reuse it later only after the notes behavior is proven.
- **Fit:** aligns with existing notes-pane context surfaces, shortcut registry, voice helpers, background AI jobs, prompt templates, in-flight button states, and toast undo patterns.
- **Adjacent issues:** note `finalReview` parity and prompt registry work are related but should remain gated unless needed for injection correctness. Nested notes should be a follow-up unless Dustin explicitly wants persisted note-of-note relationships.
- **Sufficiency:** sufficient for the pain that convened this if the user can inject a prompt against card/note/thread context and receive a new or refined note without modifying the source text.
- **Feedback speed:** source-contract and unit tests provide immediate feedback. Browser smoke gives same-session UI feedback. Model quality and context sufficiency are slower and need manual validation with real note threads.
- **Happy-path story:** Dustin opens a card's notes pane, invokes prompt injection from the active card text or a saved note, types a refinement instruction in a floating window, chooses the current segment or whole thread, presses Ctrl/Cmd+Shift+Enter, and receives a new or refined note while the parent card and original notes stay clean; if the output is wrong, Undo restores the saved content and brings back the injection prompt for another pass.

## 8. Assumptions ledger
- **Claim:** WorkLists notes are currently flat card-attached records, not nested note records.
  - **Status:** confirmed
  - **Confirm/revise by:** `openapi.js` Note schema and `server.js:createGemmaNotePayload`; revise only if Phase 3 chooses a migration.
- **Claim:** The safest v1 treats sub-note as a new flat note attached to the active card.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** Phase 3 grill question to Dustin.
- **Claim:** Current AI note create/refine already use background jobs and prompt-folder templates.
  - **Status:** confirmed
  - **Confirm/revise by:** `worklists-ai-refinement-integration.md` and `server.js` job definitions.
- **Claim:** Current note-refine undo restores saved note text, not transient prompt text.
  - **Status:** confirmed
  - **Confirm/revise by:** `public/todolist2.js:getAiNoteRefineUndoActions` and `undoAiNoteRefine`.
- **Claim:** Hard-coded AI instruction copy should not be added to server or UI infrastructure.
  - **Status:** confirmed
  - **Confirm/revise by:** prompt-file changelog entries and prompt template tests.
- **Claim:** A dedicated injection job type may be cleaner than extending existing note jobs.
  - **Status:** open
  - **Confirm/revise by:** Phase 3 spec comparison after context and output modes are locked.
- **Claim:** Full-thread context can exceed practical prompt size.
  - **Status:** open
  - **Confirm/revise by:** inspect representative WorkLists cards and define a token/character budget.
- **Claim:** `Ctrl+Shift+Plus` may conflict less than `Ctrl+Shift+Quote`.
  - **Status:** open
  - **Confirm/revise by:** Phase 3 shortcut decision and shortcut-registry conflict test.
- **Claim:** Existing known `gemma-ui.test.js:417` failure is unrelated to this report.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** future test run should compare against changelog-documented failure.

## 9. Validation plan
**Happy path**
- Open a card's notes pane from the card ellipsis or note count.
- Invoke prompt injection from the card text quick action, notes-pane card action menu, or shortcut.
- Confirm the floating window opens adjacent to the active field and does not cover actionable text.
- Type multiple lines with Enter; use voice-to-text into the injection field.
- Submit with Ctrl/Cmd+Shift+Enter.
- Confirm the action creates a new flat note attached to the active card or refines the selected note, depending on the chosen mode.
- Confirm the prompt text is cleared after successful completion and is not saved to the card or note unless intentionally generated as output.
- Confirm Undo restores previous saved content and restores/reopens the injection prompt text for refinement.

**Negative paths**
- Empty injection prompt fails visibly without creating or changing a note.
- Active card/note edited after job submission triggers the existing source-changed skip instead of overwriting newer content.
- Full-thread context above the configured limit fails visibly or truncates only with an explicit visible indicator.
- Switching cards, closing the notes pane, or opening another context window clears transient prompt state unless Undo restoration is active.
- Existing note create/save/refine shortcuts keep their current behavior outside the injection surface.
- Voice-session `Esc`, `Ctrl+Enter`, and Ctrl/Cmd+Shift+Enter behavior remains scoped and does not leak to board/global commands.
- Notes-pane card action menu selection keeps the pane open except for explicit destructive/close paths.
- Existing AI note create/refine, generated child-note creation, Copy, Copy All, Edit Notes, Delete, Move, Duplicate, markdown checkbox persistence, and unsaved draft guards remain unchanged.

**Red-green tests to add in implementation**
- Source test for injection UI markup/actions and absence of persistent prompt fields in saved note/card payloads.
- Shortcut-registry test for injection submit and voice-session ownership.
- Context-window test for open/close exclusivity and notes-pane outside-click classification.
- Gemma job/API test for structured injection payload validation and OpenAPI schema.
- Gemma prompt test proving injection/context directive copy lives in prompt files/templates.
- Browser smoke test for one real notes-pane injection create flow and viewport placement.

**Reproduction recipe / preconditions**
- Use a WorkLists board with one card containing multiline Markdown and at least two saved notes.
- Open the notes pane for that card.
- Exercise card-text origin, saved-note origin, and add-note composer origin.
- Use a model provider configuration that already passes existing AI note create/refine paths.
- Treat full `npm test` as noisy until the known `tests/gemma-ui.test.js:417` failure is resolved or intentionally excluded.

## 10. Decisions, recommendation & open variables
- **Decisions settled:**
  - Phase 1 is documentation/investigation only; no app code changes.
  - V1 investigation should assume flat card-attached notes unless Phase 3 overturns it.
  - Prompt injection text must be transient and separate from saved card/note text.
  - AI-facing instruction copy must live in prompt files/templates.
  - Existing notes AI, card AI, shortcut, voice, and context-window behavior are protected neighbors.
- **Recommendation:**
  1. In Phase 3, use grill-me/spec-writing to lock sub-note semantics, context-selection UI, shortcut, output modes, and job contract.
  2. Prefer structured server-visible injection data over client-side string concatenation.
  3. Keep the first implementation notes-pane scoped, using existing flat notes and background AI jobs.
  4. Add red tests for shortcut/context/prompt/job contracts before implementation.
  5. Gate nested note persistence, third verifier/final-review pass, and prompt registry work as follow-ups unless Phase 3 proves they are required.
- **Sequencing & gates:** Do not start implementation until Phase 3 answers the open variables below and emits a spec artifact using `C:\dustin-thomason\agents\rules\spec-writing.md`.

### Open variables to collect
- [ ] Does sub-note mean a flat card note, a UI-grouped note under another note, or a persisted parent-note relationship? - owner: Dustin
- [ ] Which context options ship in v1: current segment only, parent card only, all notes, selected notes, or whole thread? - owner: Dustin
- [ ] Which output modes ship in v1: create new note, refine selected note, refine card text, or all three? - owner: Dustin
- [ ] Which shortcut is final: Ctrl/Cmd+Shift+Plus, Ctrl/Cmd+Shift+Quote, or reuse Ctrl/Cmd+Shift+Enter only after the window is focused? - owner: Dustin + Codex
- [ ] What are the context size/token limits and visible overflow behavior? - owner: Codex proposes, Dustin approves
- [ ] Should injected note refine get deterministic `finalReview` parity with card refine? - owner: Codex
- [ ] Should the API extend `add-note` / `refine-note` or add a dedicated injection job type? - owner: Codex proposal in spec, Dustin approval
- [ ] What is the exact dated urgency or release target beyond Phase 3? - owner: Dustin

---

## 11. Plan - Next steps
### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Run Phase 3 grill-me questions | Codex + Dustin | The open variables in Section 10 are answered or explicitly deferred. |
| Write spec artifact | Codex | `spec-writing.md` rules are applied and a WorkLists prompt-injection spec exists in the canonical project folder. |
| Decide API/job contract | Codex + Dustin | Spec names whether existing jobs are extended or a new job type is added, with request/response fields. |
| Prepare implementation plan | Codex | Phase 4 plan lists files, tests, rollout gates, and protected neighbors. |
| Implement after approval | Codex | Red tests fail before behavior, pass after behavior, and targeted browser validation is documented. |

### Reconciliation checklist from required docs
#### `agents/skills/investigation/SKILL.md`
- [x] Step 1 raw facts, named instance, plain problem, urgency, and Problem Check recorded.
- [x] Step 2 assumed and confirmed class recorded, with reframing.
- [x] Step 3 acceptance criteria and non-goals locked before solution.
- [x] Step 4 source origin traced and class re-checked.
- [x] Step 5 solution compared against class, scale, generalization, fit, adjacent issues, sufficiency, feedback speed, and happy-path story.
- [x] Step 6 happy and negative validation paths recorded.
- [x] Step 7 report emitted with verdict, assumptions ledger, recommendation, open variables, and handoff table.

#### `agents/docs/problem-check.md`
- [x] Asked recorded.
- [x] Answered/drift recorded.
- [x] Should-ask recorded.
- [x] Conflation recorded.
- [x] Thin terms recorded.
- [x] Off/internal tension recorded.

#### `agents/docs/investigation-question-coverage.md`
- [x] Solve the class, not only the instance.
- [x] Scale considered for whole-thread context size.
- [x] Generalization considered and scoped to notes pane first.
- [x] Fit checked against prompt files, shortcut registry, background AI jobs, and context-window conventions.
- [x] Adjacent issues separated into follow-ups/gates.
- [x] Frontend lens covers behavior and appearance of the floating context window.
- [x] Happy and negative validation paths recorded.
- [x] Uncertainties and decisions separated.

#### `agents/docs/investigation-software-gaps.md`
- [x] Contract/source-of-truth alignment named.
- [x] Affected surfaces enumerated.
- [x] Protected neighbors named.
- [x] Detection gap recorded.
- [x] Red-green tests proposed.
- [x] Reproduction recipe and preconditions recorded.

#### `agents/docs/investigation-report.md`
- [x] Metadata completed.
- [x] Verdict and disposition completed.
- [x] Problem class, statement, contract, changed framing, root cause, alternatives, stress-test, assumptions, validation, recommendations, open variables, and handoff completed.

### Checklist
#### Investigation
- [x] This report (Sections 0-10)

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
- [ ] Document root cause / why it slipped through if this is treated as a bug

---

## 12. Definition of done (investigation gate)
- [x] **Class derived from instances, re-confirmed against root cause, and reframed answered with justification.**
- [x] Problem in one plain sentence.
- [x] Named blocked instance, with limitation noted.
- [x] Date it bites next, with external release date marked open.
- [x] Wedge plus why it is reusable within the confirmed class.
- [x] Acceptance criteria and non-goals locked before the solution was proposed.
- [x] Alternatives recorded with rejection reasons.
- [x] 30-second happy-path story.
- [x] Metric that proves it works plus feedback speed: red-green source/API/shortcut/context tests immediately; browser smoke same session; model-quality validation manually during Phase 5.
- [x] Verdict and disposition stated.
- [x] Open variables each have an owner.
- [x] Tracked action with a falsifiable done-when.
