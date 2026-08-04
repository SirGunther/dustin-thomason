# Prompt Injection for Note Refinement Spec

## Metadata

- **Status:** ready for implementation planning
- **Date:** 2026-07-31
- **Ticket:** prompt-injection-note-refinement
- **Domain:** WorkLists
- **Original ticket:** `../original-ticket.md`
- **Investigation:** `../investigations/prompt-injection-note-refinement-investigation.md`
- **Q and A ledger:** `../qa/prompt-injection-note-refinement-qa-ledger.md`

## Problem -> Requirement -> Solution

### Problem

WorkLists has an automatic AI note-refine action, but no separate way to apply a user-authored, temporary instruction to the current saved note. Putting that instruction in note or card text pollutes durable content, while reusing automatic refinement would conflate two different user intents.

### Requirement

Add Prompt Injection as a card-and-notes feature. From the current card text or saved note, the user can open a transient floating input through its ellipsis menu or `Ctrl/Cmd+Shift+Quote`, dictate or type a multiline instruction, and submit with `Ctrl/Cmd+Shift+Enter`. The request rewrites only that selected target. The instruction must never be saved as note or card data. Undo restores the prior target text and reopens the injection window with its original instruction.

### Solution

Create a saved-note ellipsis action named `Prompt Injection` and a notes-pane-scoped floating context window adjacent to that note. Introduce a dedicated `prompt-injection-note` background AI job rather than changing `refine-note`. The job accepts the note id, its source text, and transient injection text; after the existing stale-source check, one composition helper concatenates the current note text and injection text for model input. A prompt-file template supplies the AI directive. The job persists only the rewritten current note, and client-only undo metadata restores the previous note text plus the injection draft.

## Locked Decisions From Q and A

| Decision | Source | Implementation consequence |
| --- | --- | --- |
| Prompt Injection is a new feature, not automatic note refinement. | LD-001 | New action, window, job type, prompt template, completion labels, and tests. Existing `refine-note` behavior remains unchanged. |
| Only the selected current note can change. | LD-002, LD-009 | No parent-card, sibling-note, full-thread, or multi-note data in request, model input, or completion writes. |
| The entry point is the notes-pane ellipsis menu, with keyboard access. | LD-003, LD-010 | Add a saved-note ellipsis action and scoped `Ctrl/Cmd+Shift+Quote` registry command. |
| The injection text is transient. | LD-004 | Do not add a note/card field, schema field, DAL storage, or durable client setting. |
| Save before opening from edit mode. | LD-005 | Resolve the selected note to persisted text before opening; do not inject against an unsaved inline draft. |
| Enter is multiline; Ctrl/Cmd+Shift+Enter submits; voice works. | LD-006 | Window uses the existing multiline/voice ownership conventions and a focused submission shortcut. |
| Undo restores both note text and injection draft. | LD-007 | Extend the new job completion toast with an undo handler that updates the note then reopens the window. |
| Compose request input with one concatenation helper. | LD-008 | Preserve raw source text for stale guarding and undo; compose model text only after the server validates it. |

## Locked Behavior

- **Scope:** current card text or saved note. The selected target is the only AI input source and the only persisted output target.
- **No thread context:** do not send, inspect, select, concatenate, or mutate parent-card text, sibling notes, drafts, or other card data.
- **Existing behavior:** `Refine note with AI` remains an automatic, unchanged action. It is not renamed, re-routed, or given injection controls.
- **Ellipsis action:** each saved note gets a familiar ellipsis icon button in its action row. Its menu contains `Prompt Injection`; it is separate from the existing magic-wand refine button.
- **Keyboard activation:** `Ctrl/Cmd+Shift+Quote` opens Prompt Injection only when focus is in a saved note or its saved-note action row. The menu remains the alternate access path.
- **Window placement:** a transient context window opens beside the selected note and keeps actionable note text visible. It has a multiline input, voice control, submit icon button, and close control.
- **Edit-mode invocation:** if the target note is in inline edit mode, save it first. On a failed/invalid save, keep the editor open and do not open the injection window.
- **Submission:** `Enter` produces a line break. `Ctrl/Cmd+Shift+Enter` submits from the window. Empty/whitespace-only instructions do not submit.
- **Voice:** voice-to-text writes into the injection input under the current notes-pane voice-session ownership rules. It does not invoke board/global AI commands.
- **Transient lifecycle:** close, card switch, notes-pane close, or opening another context window clears the draft. A successful job clears it after the job is captured. The only restoration path is the job's Undo action.
- **Request:** the job body contains `type: "prompt-injection-note"`, `noteId`, `sourceText`, and `injectionPrompt`. The latter is permitted in the in-flight job only; it is never written to note/card data.
- **Server composition:** after locating the note and confirming `currentNote.text === sourceText`, `composePromptInjectionNoteInput(currentText, injectionPrompt)` combines the current note and user instruction once for the model call. Raw `currentText` remains the stale-write guard and `previousText` source.
- **Prompt authority:** the feature's AI directive lives in a new prompt file. Do not place behavioral prompt copy in `server.js`, `gemmaNormalize.js`, or frontend infrastructure.
- **Completion:** a changed response updates only `notes[noteIndex].text`. An unchanged response leaves the note untouched. A stale source returns the established `source-changed` skip behavior.
- **Undo:** `Undo` writes `previousText` back to the same note, reloads that note in the active pane when applicable, and reopens Prompt Injection for that same note with the original `injectionPrompt` value.
- **Persistence:** the rewritten note uses the existing note write path. No JSON shape change, migration, or public card/note endpoint is required.

## 1. Folder Hierarchy

Modified WorkLists paths:

```text
WorkLists/
  server.js
  openapi.js
  gemmaNormalize.js
  prompts/
    gemma-prompt-injection-note-directive-template.md
  public/
    todolist2.js
    todoliststyles2.css
  tests/
    gemma-ui.test.js
    gemma-normalize.test.js
    shortcut-registry.test.js
    context-windows.test.js
    api.test.js
    openapi.test.js
```

Ticket artifacts:

```text
docs/WorkLists/tickets/prompt-injection-note-refinement/
  original-ticket.md
  investigations/prompt-injection-note-refinement-investigation.md
  qa/prompt-injection-note-refinement-qa-ledger.md
  specs/prompt-injection-note-refinement-spec.md
```

## 2. New Classes

N/A - this WorkLists surface uses plain JavaScript modules and functions. No class introduction is required.

## 3. New Entities

N/A - Prompt Injection does not add a persisted entity. Notes remain flat `{ noteId, eventId, text }` records.

## 4. Modified Entities

N/A - no persisted note/card schema or property changes. The temporary job payload is not a note/card entity change.

## 5. New Migrations

N/A - JSON-backed note/card shapes do not change.

## 6. New Migration Classes

N/A - no migration classes are used by this application.

## 7. New DTOs

| Name | Path | Fields |
| --- | --- | --- |
| `PromptInjectionNoteJobRequest` | `openapi.js`, `POST /api/gemma-normalize/jobs` request schema | `type: "prompt-injection-note"`, `noteId: string`, `sourceText: string`, `injectionPrompt: string` |
| `PromptInjectionNoteJobResult` | `openapi.js`, existing job-status result union | `eventId`, `noteId`, `unchanged`, `skippedReason?`, `previousText`, `nextText` |

The response uses the existing Gemma job-status endpoint and background-job envelope. The `injectionPrompt` is intentionally excluded from persisted note/card schemas and from final result payloads.

## 8. New Projections

N/A - this application has no projection layer for notes or AI job completion.

## HTTP Surface

### `POST /api/gemma-normalize/jobs`

- **Type:** non-breaking extension to the existing background job endpoint.
- **New discriminator:** `prompt-injection-note`.
- **Request validation:** require non-empty `noteId`, `sourceText`, and `injectionPrompt`; reject unsupported types and empty values with the existing Gemma job error style.
- **Completion:** use the existing job status route. Return the standard job metadata and a result containing only note identifiers, stale/unchanged state, previous text, and next text.
- **No new card/note API:** the job owns the note rewrite; the existing `PUT /api/notes/:noteId` remains the Undo path.

Example request:

```json
{
  "type": "prompt-injection-note",
  "noteId": "note-123",
  "sourceText": "Existing note text",
  "injectionPrompt": "Make this clearer and preserve the Markdown checklist."
}
```

## Server and Prompt Design

### Job Definition And Execution

Add a `prompt-injection-note` branch to `createGemmaJobDefinition` that validates and retains the three request fields in the in-flight job payload/context.

Add `executePromptInjectionNoteGemmaJob(appInstance, job)` near `executeRefineNoteGemmaJob`.

1. Resolve runtime model and validate `noteId`, `sourceText`, and `injectionPrompt`.
2. Read notes and find the selected note; return `404` when absent.
3. Compare saved `currentText` to `sourceText`. On mismatch, write the normal prompt trace with `skippedReason: "source-changed"` and make no write.
4. Call `composePromptInjectionNoteInput(currentText, injectionPrompt)` exactly once to create model input. The helper performs the requested concatenation only; it must not mutate source text or write state.
5. Classify/normalize using the existing model pipeline with `noteContext: { mode: "prompt-injection" }` and the prompt-file directive described below.
6. Derive refined text with the existing note-result helper. Write only the selected note if the output is non-empty and differs from `currentText`.
7. Return `previousText: currentText`, `nextText`, `noteId`, `eventId`, and unchanged/stale metadata. Do not return or persist `injectionPrompt`.

Route the new type through `executeGemmaJob`, current job polling, and current job-status schema/type lists. Update prompt trace labeling so the new job is observable under its own type without recording extra durable note data.

### Prompt File

Add `prompts/gemma-prompt-injection-note-directive-template.md` following the existing note directive-template convention. It tells the model that the first concatenated segment is the current note and the second is the user instruction, that it must return a rewritten version of the current note, and that it must preserve valid Markdown unless the user instructs otherwise.

Wire this file through the existing prompt loader/normalization option rather than embedding the directive in JavaScript. Tests must establish that the prompt-file content, not infrastructure copy, supplies the behavior.

## Frontend Design

### Saved-Note Ellipsis Menu

Extend a saved note's existing action row with an icon-only ellipsis button. Its menu contains `Prompt Injection` with an appropriate existing icon-library symbol. Keep the current edit, automatic refine, copy, delete, and collapse actions unchanged.

Opening the action must:

1. Resolve the saved note id and raw saved note text from the note item.
2. If that note is currently being edited, invoke the existing inline save path and wait for success before reading the saved source text.
3. Close the ellipsis menu and open the transient window anchored to that note item.

### Transient Window State

Use a narrow notes-pane state object keyed by the selected note id. It holds only:

```js
{
  noteId,
  eventId,
  sourceText,
  injectionPrompt,
  anchorElement
}
```

Do not serialize it into a card, note, local preference, or durable job result. Clear it on the normal context-window dismissal paths. The Undo handler may recreate it from closure/pending-job metadata.

The window must receive focus when opened, render beside the target note using existing context-window positioning/exclusivity helpers, and announce a clear accessible label. It must not cover the note action row or its content controls.

### Shortcut Registry

Add `notes.promptInjection.open` with default binding `Ctrl/Cmd+Shift+Quote` and a notes-pane saved-note scope. It opens only for an identifiable saved note target; it must not fire while a different context window owns focus.

Add `notes.promptInjection.submit` scoped to the injection input, using existing `Ctrl/Cmd+Shift+Enter` bindings. Do not bind Enter alone. Existing `notes.aiRun`, card-edit AI, task AI, save, Escape, and voice-session shortcut priorities remain unchanged outside the new window.

### Voice And Submission

Reuse the current voice-to-text control pattern with the injection input as its target. Submitting stops active recognition, validates a non-empty instruction, starts the new job, marks the selected note as injection-in-flight, and immediately clears/closes the transient window.

Use a dedicated injection in-flight map or an explicit per-note operation value so a running Prompt Injection neither double-submits nor falsely disables the existing automatic-refine action. The new menu action/window submits are disabled only for that same note while the injection job is pending.

### Pending Jobs And Undo

Extend client job parsing, persistence/recovery rules, job labels, in-flight synchronization, polling, and completion routing for `prompt-injection-note`. Preserve `injectionPrompt` only as transient client pending-job metadata until completion/Undo expiration; do not display it as saved note content.

On successful changed completion, show a dedicated success message and `Undo`. The undo handler:

1. Calls `ApiService.updateNote(noteId, previousText)`.
2. Reloads the active notes pane when it displays `eventId`.
3. Reopens the injection window anchored to the selected note, setting its input to the original `injectionPrompt`.

On unchanged/stale/failed completion, show the existing error or source-changed feedback without rewriting notes. A stale result must not open an Undo action that overwrites newer content.

## Cross-Cutting

- **Parent epic:** N/A - none supplied.
- **Feature flag:** N/A - no feature flag requested.
- **Authorization:** N/A - this local WorkLists surface has no authorization change.
- **Registries and module wiring:** extend existing Gemma job, prompt-loader, shortcut-registry, context-window, and pending-job wiring only.
- **Ports, domain events, outbox, exceptions:** N/A - no such architecture is used here. Retain existing Gemma job error behavior.
- **Changelog:** after verified implementation, update `C:\\dustin-thomason\\docs\\WorkLists\\worklists-app-changelog.md` with the distinct feature behavior, shortcut, undo flow, prompt file, API discriminator, and focused validation results.

## Validation Plan

### Server And API Tests

- Accept a valid `prompt-injection-note` job and reject missing/blank `noteId`, `sourceText`, or `injectionPrompt`.
- Include `prompt-injection-note` in OpenAPI request and status enum/schema assertions.
- Confirm the selected note alone is read/written; parent card and other notes remain byte-for-byte unchanged.
- Confirm the composition helper receives current saved text plus injection text and that output derives from the prompt-injection directive.
- Confirm a source mismatch returns `source-changed` and performs no note write.
- Confirm unchanged/empty model output performs no note write.
- Confirm completion result contains `previousText` and `nextText` but not `injectionPrompt`.

### Prompt Tests

- The new injection directive is loaded from `prompts/gemma-prompt-injection-note-directive-template.md`.
- No Prompt Injection directive copy is hard-coded in server, normalization, or UI infrastructure.
- The generated model prompt distinguishes current note content from the user instruction and uses the new prompt-injection mode.

### Frontend Contract Tests

- A saved note action row renders its ellipsis trigger and `Prompt Injection` menu item; existing automatic-refine action remains present and unchanged.
- Menu invocation for a saved note opens the focused transient window adjacent to that note.
- Invocation during inline edit saves first and does not open on save failure.
- `Ctrl/Cmd+Shift+Quote` opens only for a saved-note target; it does not collide with `notes.aiRun` or global shortcuts.
- Enter is multiline; `Ctrl/Cmd+Shift+Enter` submits only from the injection window.
- Voice input targets the injection field and retains existing voice stop/Escape ownership.
- Card switch, pane close, Escape, and another context window clear the injection state.
- Submit creates a `prompt-injection-note` job with exact `noteId`, source text, and injection text; it does not send other notes or card text.
- Only the selected note shows injection pending state; automatic refine remains separately operable per current conventions.
- Completion updates only the selected note and opens an Undo action.
- Undo restores prior note text, reopens the same note's injection window, and restores the original injection input.
- Existing notes-pane menu dismissal/exclusivity behavior, note editing, create-note AI, automatic note refine, copy, delete, and collapse behavior remain covered.

### Manual Validation

1. Open a card with several saved notes; launch Prompt Injection from one saved note's ellipsis. Verify only that note is available to the flow.
2. Type a multiline instruction, submit with `Ctrl/Cmd+Shift+Enter`, and verify that only the selected note changes.
3. Use voice input, then submit; verify voice ownership and the changed note.
4. Click Undo; verify note text reverts and the exact instruction returns in the anchored window.
5. Close/switch contexts without submitting; verify the draft is gone and no card/note data changed.
6. Begin inline editing a note, invoke Prompt Injection, verify save-first behavior, and repeat with an invalid edit to verify no window opens.
7. Verify the existing automatic `Refine note with AI` flow behaves identically to its pre-feature behavior.

The known unrelated `tests/gemma-ui.test.js:417` voice-session shortcut-scope failure remains baseline noise unless this change alters that assertion.

## Implementation Sequence

1. Add red server/OpenAPI tests for the new job discriminator, validation, selected-note-only write, stale guard, and result redaction.
2. Add the prompt-injection directive template and normalization tests.
3. Implement job definition, composition helper, execution, routing, status schema, and prompt trace support.
4. Add red shortcut/context-window/UI contract tests.
5. Add saved-note ellipsis menu and transient-window state/UI/CSS.
6. Add scoped activation, submit, and voice ownership behavior.
7. Wire pending-job tracking, completion, in-flight state, and Undo restoration.
8. Run focused tests and manually validate notes-pane placement, keyboard, voice, stale-write, and Undo behavior.
9. Update the changelog after validation.

## Non-Goals

- Changing parent card text.
- Creating, reading, selecting, or modifying sibling notes or full note threads.
- Nested note persistence or a note hierarchy.
- Replacing, renaming, or altering existing automatic note refinement.
- Persisting the injection prompt in card/note data, user settings, or completed job results.
- Adding a generic app-wide prompt-injection framework.
- Adding a third model pass or final-review parity work.
