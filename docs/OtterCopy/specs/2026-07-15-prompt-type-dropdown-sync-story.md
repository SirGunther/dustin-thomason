# Story Spec: OtterCopy Prompt Type Dropdown Synchronization

## Source
- Investigation: `docs/OtterCopy/investigations/2026-07-15-prompt-type-dropdown-sync.md`
- App repo: `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\OtterCopy`
- Scope: browser-extension popup prompt selection state only

## Problem -> Requirement -> Solution

### Problem
The OtterCopy popup has two prompt-selection truths. The top-level Type dropdown stores its selected prompt in `ottercopy:ui:refine`, while Prompt Settings and extended refinement depend on `promptStore` active state (`ottercopy:activePromptId`). This allows the dropdown, settings panel, header summary, failed-attempt restore, and extended refinement execution context to diverge.

### Requirement
Changing the Type dropdown must update the canonical active prompt strategy immediately. Every visible prompt selection surface must reflect the same prompt id, and Basic/Extended refinement must run against that prompt unless an existing override mechanism deliberately supersedes it.

### Solution
Make `ottercopy:activePromptId` the canonical active prompt state for prompt strategy. Update `popup.js` so the Type dropdown writes through `OtterCopyPromptStore.activatePrompt()`, all prompt UI mirrors refresh from `OtterCopyPromptStore.getPrompts()` / `getActivePrompt()`, and failed-attempt restore reuses the same synchronization path. Keep `UI_PREFS_KEY` for Extended preference only, not prompt authority.

## Acceptance Criteria
| Criterion | Done when |
|-----------|-----------|
| Type dropdown writes canonical prompt state | Changing Type calls the prompt-store activation path and `ottercopy:activePromptId` matches the selected prompt id. |
| Header summary stays in sync | `#activePromptSummary` updates immediately after Type changes, Prompt Settings changes, and failed-attempt restore. |
| Prompt Settings stays in sync | The active row/button in `#promptList` reflects the same prompt as the Type dropdown while the panel is open. |
| Basic refinement preserves selected prompt behavior | Basic refine still sends/uses the selected prompt id, and no legacy stale UI pref overrides the prompt-store active prompt. |
| Extended refinement uses selected active prompt | For active-prompt-sourced extended refinement, changing Type before running Extended causes `getActivePrompt()` to resolve the selected prompt. |
| Failed/cancelled restore is coherent | Restoring `LAST_ATTEMPT_KEY.inputs.promptId` updates dropdown, active prompt store, header, settings row, and retry execution state together. |
| Neighbor behaviors unchanged | Exact copy, model pickers, provider settings, direction override, manual transcript modes, latest-result polling, cancellation, and notifications remain unchanged. |

## 1. Folder Hierarchy
New docs artifact only:

```text
docs/
  OtterCopy/
    specs/
      2026-07-15-prompt-type-dropdown-sync-story.md
```

Application code changes, when implemented later, are expected to stay in the existing extension root:

```text
OtterCopy/
  popup.js
```

N/A for `callisto-back-end-neptune/src/` and `og-atlas-front-end/src/` - this is a personal browser-extension popup story, not a Callisto/Atlas app story.

## 2. New Classes (Name + Path)
N/A - no new classes are required. The implementation should use small popup-level functions in existing `popup.js`, not introduce classes.

Expected new or refactored functions in `popup.js`:

| Function / helper | Path | Purpose |
|-------------------|------|---------|
| `syncPromptSelection` or equivalent | `popup.js` | Write a selected prompt id through `OtterCopyPromptStore.activatePrompt()` and refresh prompt views. |
| `refreshPromptSelectionViews` or equivalent | `popup.js` | Re-render Type dropdown, header summary, and Prompt Settings active state from `promptConfigs`. |
| `onRefineTypeChange` or equivalent | `popup.js` | Replace the current inline Type `change` handler with the canonical write-through flow. |

Names may vary, but the implementation must keep one canonical prompt-selection synchronization path.

## 3. New Entities
N/A - no database, TypeORM entity, table, or persisted backend schema is introduced.

## 4. Modified Entities
N/A - no database or shared entity model is modified.

## 5. New Migrations (File Names)
N/A - no schema migration is required.

## 6. New Migration Classes
N/A - no migration classes are required.

## 7. New DTOs
N/A - no HTTP/API request or response DTOs are introduced.

Internal browser-extension storage semantics are clarified:

| Storage key | Change |
|-------------|--------|
| `ottercopy:activePromptId` | Canonical prompt strategy state. Type dropdown should write through this key via `promptStore.activatePrompt()`. |
| `ottercopy:ui:refine` | Retain for Extended preference only; legacy `promptId` must not override active prompt state. |
| `ottercopy:ui:lastAttempt` | Restored `inputs.promptId` must sync through canonical prompt activation before retry. |

## 8. New Projections (and Domain Inputs if Relevant)
N/A - no backend projection/domain input is introduced.

For popup state, the implementation should treat the derived prompt selection view as:

| View state | Source |
|------------|--------|
| Type dropdown selected value | Active prompt from `promptConfigs` after `getPrompts()` / `activatePrompt()` |
| Header prompt summary | Active prompt from `OtterCopyPromptStore.getActivePrompt(promptConfigs)` |
| Prompt Settings active row | Same active prompt from `promptConfigs` |
| Extended toggle enabled/disabled | Current Type prompt id checked against `EXTENDED_PIPELINE_BY_PROMPT_ID` |

## Cross-Cutting
- Parent investigation: `docs/OtterCopy/investigations/2026-07-15-prompt-type-dropdown-sync.md`.
- Feature flags: N/A - no feature flag exists for this extension behavior.
- Companion tickets: N/A - no ClickUp/PRDV ticket supplied.
- Storage authority: `promptStore.js` owns `ottercopy:activePromptId`; popup mirrors must not become independent authorities.

## Optional Callouts

### HTTP Surface
N/A - browser extension only; no HTTP route or API contract changes.

### Registries and Module Wiring
N/A - no application registry/module wiring exists for this extension popup change.

### Ports
N/A - no domain ports or infrastructure adapters are added.

### Domain Events / Dispatchers / Outbox
N/A - no domain events, dispatchers, or outbox behavior.

### Domain Exceptions
N/A - no domain exceptions. Existing popup error handling should continue to surface prompt-store failures via status text or console debug without breaking the popup.

### Authorization
N/A - no auth, roles, guards, or policy changes.

### Spec Tests
No persistent test harness exists in this repo. Required verification is a loaded-extension manual pass plus syntax checks.

Recommended gates:

| Gate | Command / action | Done when |
|------|------------------|-----------|
| syntax | `node --check popup.js` | Popup script parses after changes. |
| syntax regression | `node --check background.js` | Background script still parses, even if untouched. |
| syntax regression | `node --check promptStore.js` | Prompt store still parses, even if untouched. |
| manual red/green | Loaded extension before/after behavior | Before fix, dropdown can diverge from active prompt; after fix, all prompt mirrors agree. |
| manual happy path | Summary/Variables/Refinement/Handoff prompt selection | Dropdown, header, settings, Basic/Extended execution state agree. |
| manual negative path | Direction override, manual transcript modes, exact copy, model/provider settings | Neighbor behaviors remain unchanged. |

## Implementation Notes
- Do not update `background.js` message contracts unless implementation evidence proves popup-level canonicalization is insufficient.
- Do not let stale `UI_PREFS_KEY.promptId` override `ottercopy:activePromptId` on popup load.
- If adding `chrome.storage.onChanged`, scope it to prompt-store keys and `UI_PREFS_KEY`; avoid broad storage re-rendering.
- If Type changes and the user immediately clicks Refine, `runRefine()` must not dispatch before prompt activation completes.
- Extended Handoff remains file-sourced by current design; this story should not change its governing prompt source.
