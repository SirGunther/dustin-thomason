# Investigation Report: OtterCopy Prompt Type Dropdown Synchronization Bug

## Metadata
- **Status:** done
- **Disposition:** proceed with conditions
- **Date:** 2026-07-15
- **Owner:** Dustin Thomason / Codex investigation handoff
- **Location:** `docs/OtterCopy/investigations/2026-07-15-prompt-type-dropdown-sync.md`
- **Ticket:** none; personal OtterCopy incident report
- **Domain:** software
- **References / evidence:**
  - `agents/skills/investigation/SKILL.md`
  - `agents/docs/problem-check.md`
  - `agents/docs/investigation-report.md`
  - `agents/docs/investigation-question-coverage.md`
  - `agents/docs/investigation-software-gaps.md`
  - `docs/OtterCopy/ottercopy-app-changelog.mdc`
  - `docs/OtterCopy/OtterCopy-app-changelog.md`
  - OtterCopy app repo: `popup.js`, `popup.html`, `promptStore.js`, `background.js`, `prompts/custom/index.json`

---

## 0. Verdict
Proceed with a narrow synchronization fix after review. The strongest path is to treat `promptStore`'s `ottercopy:activePromptId` as the canonical active prompt strategy, then make the Type dropdown, settings prompt list, header summary, failed-attempt restore, and extended/basic execution surfaces observe or write through that same state. This is viable as a small popup-layer repair, but it is not yet a production approval or a code implementation plan; live loaded-extension validation is still required because the repo has no persistent test harness.

- **Strongest path:** canonicalize prompt selection around `promptStore.activatePrompt()` / `getActivePrompt()` and make UI mirrors refresh from that source.
- **Not yet proven / not approved:** exact live reproduction in Chrome, loaded-extension green path, and whether a persistent harness should be added later.

## 1. Problem class
- **Class the request assumed:** Dropdown event/listener binding bug: the Type dropdown's `onChange` does not update the core prompt strategy.
- **Confirmed class:** Source-of-truth drift across UI preference state, prompt-store active state, and execution readers.
- **Reframed?** yes, from **dropdown listener bug** to **prompt strategy state drift**, triggered at Step 4 when code evidence showed Basic refinement receives a selected `promptId`, while extended refinement still reads the prompt store's active prompt.
- **What the confirmed class implies:** The fix must not merely pass more values from the dropdown. It must identify the authoritative prompt strategy state and ensure all UI mirrors and execution paths either write through it or deliberately bypass it.

## 2. Problem statement
- **Named instances:** The user-provided OtterCopy incident report on 2026-07-15. No concrete failing run id, transcript, or Chrome extension log was supplied.
- **One sentence:** When a user changes the OtterCopy Type dropdown, the visible selected prompt can diverge from the prompt store state that settings and extended refinement treat as active.
- **Distinct problems:**
  - Dropdown selection is persisted separately in `ottercopy:ui:refine` instead of writing the active prompt store.
  - Settings visibility can show a different active prompt than the top-level Type dropdown.
  - Extended refinement can read the active prompt store instead of the dropdown's UI preference.
  - Failed-attempt restore can restore a dropdown `promptId` without synchronizing active prompt state.
- **Urgency:** The next time a user changes Type and either runs extended refinement, checks Prompt Settings, or retries a restored failed/cancelled attempt.
- **Wedge:** Make prompt selection a single-store contract: top-level Type selection writes `ottercopy:activePromptId`, and all prompt selection UI refreshes from `promptStore.getPrompts()`. This is reusable for future prompt-library additions and custom prompts.

### Problem Check

## The question
---
### Asked
|  |  |
|---|---|
| **finding** | The request says the Type dropdown is disconnected from core prompt functionality. |
| **evidence** | "drop-down menu is disconnected" |

### Answered
|  |  |
|---|---|
| **finding** | The code investigation is actually working on prompt strategy state ownership and propagation. |
| **drift** | "fix dropdown onChange" -> "unify active prompt state across dropdown, settings, restore, and execution" |
| **evidence** | "active prompt configuration service" |

### Should-ask
|  |  |
|---|---|
| **finding** | Which state owns the active prompt strategy, and which surfaces are only mirrors? |
| **why** | This decides whether to patch one listener or repair the state contract that settings and execution already depend on. |

## Flags
---
### Conflation
|  |  |
|---|---|
| **finding** | UI selection, execution routing, settings transparency, and persistence are treated as one problem. |
| **consequence** | Fixing Basic run routing alone would not necessarily fix settings or extended refinement. |
| **evidence** | "settings panel should reflect" / "propagate immediately" |

### Thin
|  |  |
|---|---|
| **finding** | No concrete failing run, selected prompt, expected prompt, or debug result was supplied. |
| **evidence** | "Observed behavior" only |

### Off
|  |  |
|---|---|
| **finding** | The report says selecting a prompt has no impact, but code shows Basic refinement passes the selected `promptId`. |
| **consequence** | The claim is too broad; the defect is strongest for active-state transparency and extended refinement, not necessarily every Basic run. |
| **evidence** | "no impact" -> `copyFromActiveTab("ai-refine", promptId)` |

## 3. The contract
### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| Changing the Type dropdown updates the canonical active prompt state immediately. | needs-proof | Implement write-through to `promptStore.activatePrompt()` and validate `ottercopy:activePromptId` changes. |
| Prompt Settings reflects the same active prompt as the Type dropdown while open. | needs-proof | Refresh Prompt Settings from `promptConfigs` after dropdown changes or storage changes. |
| Header prompt summary reflects the currently active prompt. | needs-proof | Refresh `activePromptSummary` from `getActivePrompt(promptConfigs)`. |
| Basic refinement uses the selected prompt. | documented | Current code passes `promptId`; still revalidate after canonicalization. |
| Extended refinement uses the intended active prompt for prompt-driven pipelines. | needs-proof | Ensure dropdown selection writes active prompt before dispatch, then validate `runExtendedRefinementJob` reads it. |
| Failed/cancelled attempt restore keeps dropdown, active prompt, and retry execution aligned. | needs-proof | Restore `inputs.promptId` through the same active prompt sync path. |
| Existing neighboring behaviors remain unchanged. | needs-proof | Run targeted manual checks for exact copy, model/provider settings, direction override, manual transcript modes, and notifications. |

### Non-goals / out of scope
- Do not implement code in this investigation artifact.
- Do not redesign the popup or prompt library UI.
- Do not unify prompt-builder architecture or extended pipelines.
- Do not change provider/model storage, notification behavior, transcript extraction, or manual transcript modes.
- Do not add dependencies or a persistent test harness unless separately approved.
- Do not change Extended Handoff's file-sourced governing prompt unless a later investigation proves that requirement.

## 4. What changed since the request was created
- **Shifted from:** "the dropdown is non-functional" -> **to:** "the dropdown and prompt-store active state are separate sources of truth."
- **What that buys us:** It prevents an over-broad background rewrite and focuses the likely fix on prompt state ownership and UI refresh.
- **What it still needs to prove:** Loaded-extension reproduction, especially for immediate change-then-run timing and restored failed-attempt retry state.

## 5. Why it exists
- **Origin traced to:** The June 30 dropdown refactor introduced a UI preference layer for `promptId` without making it the prompt store's active prompt.
- **Evidence:**
  - Changelog says the dropdown is populated from `promptConfigs`, sends selected `promptId` on Basic, and persists `promptId + extended`: `docs/OtterCopy/ottercopy-app-changelog.mdc:184-191`.
  - Changelog says Basic falls back to active prompt but extended paths were untouched: `docs/OtterCopy/ottercopy-app-changelog.mdc:199`.
  - Changelog says the prompt store active selection is `ottercopy:activePromptId`: `docs/OtterCopy/OtterCopy-app-changelog.md:39-40`, `:702`.
  - `promptStore.js:8-20` documents `ottercopy:activePromptId` as user-specific prompt state.
  - `promptStore.js:124-157` applies and reads active prompt state.
  - `promptStore.js:206-213` is the active prompt write API.
  - `popup.js:92-95` changes Type by only calling `updateExtendedGating()` and `saveUiPrefs()`.
  - `popup.js:184-190` persists `promptId` into `ottercopy:ui:refine`, not `ottercopy:activePromptId`.
  - `popup.js:1212-1219` writes active prompt only from Prompt Settings.
  - `background.js:700-706` Basic refinement uses selected `promptId` when supplied, with active prompt fallback.
  - `background.js:919-921` extended refinement reads the active prompt store for active-prompt-sourced pipelines.
  - Search across the narrow path found no `chrome.storage.onChanged` listener, so there is no settings listener that reconciles prompt store changes while the popup is open.
- **Class re-check:** held as reframed. Root cause evidence confirms source-of-truth drift rather than a total lack of dropdown dispatch.

### Contract / source-of-truth alignment
- **Authority:** `promptStore` active selection, stored as `ottercopy:activePromptId`.
- **Mirrors:** Type dropdown value, `activePromptSummary`, Prompt Settings row/button state, failed-attempt snapshot `inputs.promptId`, and legacy `ottercopy:ui:refine.promptId`.
- **Execution readers:** Basic can use explicit `promptId`; extended refinement reads `getActivePrompt()` for the `refinement` pipeline.
- **Drift risk:** Any mirror that sets `refineType.value` without calling `activatePrompt()` can display a prompt that execution/settings do not treat as active.

### Affected surfaces and completeness proof
- **Surfaces:**
  - Type dropdown markup: `popup.html:51-58`.
  - Prompt Settings list/form: `popup.html:218-241`.
  - Type change/init/prefs/restore/list rendering: `popup.js:92-178`, `:184-193`, `:230-276`, `:632-640`, `:1117-1219`.
  - Prompt store authority: `promptStore.js:1-22`, `:124-157`, `:164-213`, `:216-247`.
  - Basic and extended execution reads: `background.js:674-706`, `:865-921`.
  - Prompt library ids: `prompts/custom/index.json`.
- **Completeness proof:** The requested search terms were run across exactly `popup.js`, `popup.html`, `promptStore.js`, `background.js`, and `prompts/custom/index.json`. Matches were limited to the surfaces above; no `chrome.storage.onChanged` match appeared in those files.

### Protect-the-neighbors
- Exact transcript copy should remain unchanged because it uses `.copy-action` button flow, not prompt selection.
- Model pickers should remain unchanged because they already have separate active/final-pass store APIs and refresh functions.
- Provider settings and config import/export should remain unchanged because prompt selection does not touch `providerStore` or model credential resolution.
- Direction override should remain unchanged because both Basic and extended paths explicitly let direction override governing prompt when enabled.
- Manual transcript supplement/override should remain unchanged because transcript resolution is independent of prompt selection.
- Notifications, latest-result polling, cancellation, and service-worker keepalive should remain unchanged because prompt selection only influences governing prompt choice before model calls.

### Detection gap
- There is no persistent JS test harness or package-level gate for popup behavior, consistent with prior changelog entries.
- Prior verification named dropdown population and selection persistence, but did not require proving `ottercopy:activePromptId`, Prompt Settings active row, and extended refinement all moved together.
- Red/green proof should reproduce a dropdown change where settings or extended refinement still observes the previous active prompt before the fix, then prove all mirrors observe the new active prompt after the fix.

## 6. Alternatives considered
| Alternative | Rejected because |
|-------------|------------------|
| Dropdown-only UI fix | It may update labels or UI prefs while leaving `ottercopy:activePromptId` stale. |
| Pass `promptId` into extended jobs | Broader background message contract change; still does not make settings/header active state transparent. It also risks blurring the existing file-sourced Handoff behavior. |
| Canonicalize `ottercopy:activePromptId` | Preferred. It aligns with the documented prompt store and keeps Basic/extended/settings behavior coherent. |
| Add scoped storage listener sync | Keep as likely part of the implementation if the popup must respond to prompt store changes while open. It should be scoped to prompt keys to avoid broad storage churn. |
| Migrate old `ottercopy:ui:refine.promptId` into active state | Risky because stale UI prefs could override a deliberate Prompt Settings active selection with no timestamp or provenance. |
| Add a persistent test harness now | Out of scope for this investigation. Worth a follow-up if prompt UI regressions continue. |

## 7. Solution & stress-test
- **Proposed solution:** In a later implementation, make Type dropdown selection write through `promptStore.activatePrompt()`, refresh all prompt UI mirrors from `getPrompts()` / `getActivePrompt()`, keep `UI_PREFS_KEY` for Extended preference only, restore failed-attempt prompt through the same sync path, and optionally add a scoped `chrome.storage.onChanged` prompt listener for live popup synchronization.
- **Solves the confirmed class?** Yes, if every prompt selection surface writes to or refreshes from `ottercopy:activePromptId`, it addresses the state-drift class rather than only this dropdown occurrence.
- **Scale:** Holds as built-ins and custom prompts grow because it relies on prompt ids already enumerated by the prompt library and prompt store.
- **Generalization:** Do not introduce a generic state bus. A small prompt-selection refresh helper is enough; broader abstraction would overfit this popup.
- **Fit:** Matches existing model picker precedent: top-level selector writes canonical store state and refreshes settings when open.
- **Adjacent issues:** Legacy `UI_PREFS_KEY.promptId` should be de-authorized now. Persistent test harness can be follow-up unless implementation proves manual validation is too slow or ambiguous.
- **Sufficiency:** Covers the pain that convened this: user-visible Type selection, settings transparency, and active execution context alignment. It does not solve unrelated prompt-builder complexity.
- **Feedback speed:** Manual loaded-extension feedback is immediate once implemented. Automated feedback is slow/absent until a harness exists.
- **Actor / action / moment:** User selects a prompt from the popup Type dropdown, before running Basic or Extended refinement, and expects that selected prompt to be the active strategy shown in settings and used by execution.
- **Happy-path story:** A user opens OtterCopy, chooses Summary from Type, sees the header/settings reflect Summary immediately, runs Basic refinement, gets Summary output, reopens the popup, and still sees Summary as the active prompt without opening settings.

## 8. Assumptions ledger
- **Claim:** The incident report is sufficient as the named instance.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** Replace with a concrete run id/log if supplied later.
- **Claim:** `ottercopy:activePromptId` is the authoritative prompt strategy state.
  - **Status:** confirmed
  - **Confirm/revise by:** `promptStore.js` comments/API and changelog current state.
- **Claim:** Basic refinement is not fully disconnected because it receives `promptId`.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** Loaded-extension Basic run with different selected prompts.
- **Claim:** Extended refinement can diverge because it reads active prompt state.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** Loaded-extension extended refinement after dropdown-only selection without active store update.
- **Claim:** No current settings listener synchronizes prompt storage changes while popup is open.
  - **Status:** confirmed by search in narrow files
  - **Confirm/revise by:** Re-run `rg "chrome.storage.onChanged"` before implementation if files change.
- **Claim:** Existing header summary and settings active row are sufficient visual confirmation.
  - **Status:** open
  - **Confirm/revise by:** User review or loaded-extension UX check.
- **Claim:** A small popup-layer fix is enough; no background contract change is required.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** Implementation validation of Basic and extended prompt selection.

## 9. Validation plan
**Happy path**
- Load the extension with at least the four built-ins: Refinement, Summary, Variables, Handoff.
- Change Type to Summary.
- Confirm `ottercopy:activePromptId` becomes `prompt-summary`.
- Confirm header summary and Prompt Settings active row show Summary.
- Run Basic refinement and confirm Summary prompt behavior.
- Change Type to Refinement, enable Extended, immediately click Refine.
- Confirm extended refinement starts after active prompt state is set and uses the selected active prompt.
- Stop or force a failed run, reopen, and confirm restored Type, active prompt state, and retry execution agree.

**Negative paths**
- Select Summary or Variables and confirm Extended disables and clears visibly.
- Delete an active custom prompt and confirm prompt store fallback, dropdown, header, and settings row agree.
- Edit or reset a built-in and confirm active selection is preserved unless intentionally changed.
- Use Direction as prompt override and confirm it still supersedes the active prompt for that run.
- Use manual transcript supplement/override and confirm prompt selection does not affect transcript source resolution.
- Confirm exact copy, latest-result copy, debug-log copy, model pickers, provider settings, and notifications still behave as before.
- Confirm stale `ottercopy:ui:refine.promptId` does not override `ottercopy:activePromptId` on popup open.

**Metric and feedback speed**
- Metric: 100% of checked prompt-selection mirrors agree on the same prompt id after each selection/change/restore scenario.
- Feedback speed: immediate in a loaded-extension manual pass after implementation; no automated feedback until a harness exists.

## 10. Decisions, recommendation & open variables
- **Decisions:**
  - Treat the problem as prompt state drift, not a purely disconnected dropdown.
  - Use `ottercopy:activePromptId` as canonical state.
  - Do not implement app code as part of this investigation artifact.
  - Do not add dependencies or a persistent test harness in this step.
- **Recommendation:** Proceed to a narrow implementation only after this report is reviewed. Implement popup prompt-state synchronization first; then validate Basic, extended, settings, and restore flows in a loaded extension.
- **Sequencing & gates:**
  - Gate 1: report reviewed and accepted.
  - Gate 2: code changes limited to the prompt-selection synchronization surface unless new evidence appears.
  - Gate 3: syntax checks pass.
  - Gate 4: loaded-extension happy and negative paths pass.

### Open variables to collect
- [ ] Concrete failing run/log, if available - owner: Dustin
- [ ] Whether existing header/settings active indicators are enough visual confirmation - owner: Dustin
- [ ] Whether cross-popup or cross-device `chrome.storage.onChanged` sync is required in v1, or only local popup event sync - owner: implementer, confirm with Dustin if UX tradeoff changes scope
- [ ] Whether a persistent jsdom/Vitest harness should be a follow-up - owner: Dustin / implementer

---

## 11. Plan - Next steps
### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Review investigation report | Dustin | Dustin accepts the confirmed class, contract, and validation gates or requests revisions. |
| Implement narrow prompt sync | Implementer | Type dropdown writes canonical active prompt, settings/header/dropdown stay aligned, no unrelated modules touched. |
| Validate loaded extension | Implementer | All happy and negative validation paths in Section 9 pass or failures are recorded with follow-up owner. |
| Decide harness follow-up | Dustin / implementer | Explicit yes/no on creating a persistent popup test harness after this bug fix. |

### Checklist
#### Investigation
- [x] This report (Sections 0-10)
- [x] Problem Check completed
- [x] Source-of-truth alignment identified
- [x] Affected surfaces enumerated
- [x] Neighbor regressions named
- [x] Detection gap recorded

#### Project Spec
- [x] Draft open questions / unknowns
- [ ] Create implementation spec, only if requested after report review

#### Development
- [ ] Create implementation branch if needed
- [ ] Begin implementation only after report review

#### Testing & Validation
- [ ] Test and validate implementation locally after code changes

#### Deploy & PR
- [ ] Push/open PR only if requested

#### Ticket Closeout
- [ ] If treated as a bug ticket, document root cause and why it slipped through

---

## 12. Definition of done (investigation gate)
- [x] Class derived from instances, re-confirmed against root cause, and reframing justified
- [x] Problem in one plain sentence
- [x] Named blocked instance
- [x] Date/trigger when it bites next
- [x] Wedge and why it is reusable within the confirmed class
- [x] Acceptance criteria and non-goals locked before implementation
- [x] Alternatives recorded with rejection reasons
- [x] 30-second happy-path story
- [x] Metric that proves it works and feedback speed
- [x] Verdict and disposition stated
- [x] Open variables each have an owner
- [x] Tracked action with falsifiable done-when
