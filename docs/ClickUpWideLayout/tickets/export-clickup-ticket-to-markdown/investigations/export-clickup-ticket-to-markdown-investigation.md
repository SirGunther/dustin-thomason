# Investigation Report: Export ClickUp Ticket To Markdown

## Metadata
- **Status:** done
- **Disposition:** proceed with conditions
- **Date:** 2026-07-20
- **Owner:** Codex / Dustin
- **Location:** `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/investigations/export-clickup-ticket-to-markdown-investigation.md`
- **Ticket:** local ClickUpWideLayout task, captured in `../original-ticket.md`
- **Domain:** software, browser extension
- **References / evidence:** `manifest.json`, `popup.html`, `popup.js`, `content.js`, `background.js`, `C:\dustin-thomason\docs\ClickUpWideLayout\ClickUpWideLayout-app-changelog.md`, `C:\dustin-thomason\agents\docs\browser-loop-setup.md`, Chrome extension docs for `activeTab`, `scripting`, and `downloads`, ClickUp docs for Tasks and Get Task.

---

## 0. Verdict

Proceed with a browser-first export in the extension popup. The existing extension already has the necessary MV3 shape for user-gesture DOM capture: popup buttons, `activeTab`, `scripting`, ClickUp host permission, task id/title extraction, and a content helper for task links. The strongest v1 is to collect visible task data from the active ClickUp page, map it into the original-ticket Markdown format, and trigger a Blob/object-URL download named `{ticket-id}-original-ticket.md`. API access should remain a fallback only, because the ClickUp Get Task endpoint can return `markdown_description` and `custom_fields` but requires authentication/token/workspace decisions that would add product and security scope.

- **Strongest path:** DOM capture first, API fallback deferred unless live browser proof shows visible fields are insufficient.
- **Not yet proven / not approved:** exact live ClickUp selectors and rich-text preservation quality need verification in an attached ClickUp browser session. CDP at `localhost:9222` was unavailable during this investigation.

## 1. Problem class

- **Class the request assumed:** export/integration feature, originally framed partly through API research.
- **Confirmed class:** browser-extension DOM capture plus Markdown transformation.
- **Reframed?** yes, from API-first ticket retrieval to browser-first active-page export. The user clarified that this work belongs to `ClickUpWideLayout`, and the Atlas/PRDV ticket is a format reference only.
- **What the confirmed class implies:** the v1 solution should preserve the current no-login extension behavior and use the data the user is already authorized to view in ClickUp. API token storage and OAuth are not v1 unless DOM capture fails the required fields.

## 2. Problem statement

- **Named instances:** Dustin wants to capture ClickUp tickets into `original-ticket.md` style artifacts without manually copying title, description, metadata, and links.
- **One sentence:** The extension can copy a ClickUp task link, but it cannot export the active task into a structured Markdown original-ticket file.
- **Distinct problems:**
  - No popup action downloads a Markdown artifact.
  - Current copy actions capture only id/title/link, not description or metadata.
  - The source-of-truth project was briefly conflated with Atlas; the correct target is the browser extension.
- **Urgency:** the next ClickUp ticket onboarding that needs a Phase 0 original-ticket artifact.
- **Wedge:** one active ClickUp task, one popup button, one Markdown file download.

## 3. The contract

### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| Popup exposes a clear export action while viewing a ClickUp task | needs-proof | Add button and verify it only fails visibly when task data is unavailable |
| Downloaded filename is `{ticket-id}-original-ticket.md` | needs-proof | Strip leading `#`, sanitize filesystem-unsafe characters, assert exact filename |
| Markdown includes title, id, URL, description, metadata, and downstream artifact placeholders | needs-proof | Implement formatter and inspect generated file |
| Rich text remains Markdown-friendly | needs-proof | Convert common ClickUp DOM nodes for paragraphs, headings, lists, links, emphasis, and code |
| No recurring login prompt | covered by approach | Use active page DOM in v1; no token prompt or OAuth setup |
| Existing copy and layout toggle behavior unchanged | needs-proof | Run syntax checks and manual regression on existing buttons |

### Non-goals / out of scope
- Building OAuth or API-token settings in v1.
- Exporting comments/activity history unless separately requested.
- Creating Atlas ticket artifacts from this extension task.
- Solving ClickUp's full internal rich-text model; v1 preserves common rendered structure from the browser DOM.

## 4. What changed since the request was created

- **Shifted from:** API-oriented ClickUp export and accidental Atlas-ticket framing.
- **To:** `ClickUpWideLayout` browser extension exporting the active visible ClickUp task.
- **What that buys us:** no new login flow, smaller permission surface, faster implementation, and alignment with the user-visible task page.
- **What it still needs to prove:** live selectors for description, visible metadata, and custom fields across current ClickUp task layouts.

## 5. Why it exists

- **Origin traced to:** `ClickUpWideLayout` was built for layout toggling and quick copy snippets. `popup.js` extracts only task id/title/link; no code collects description/metadata, formats an original-ticket artifact, or starts a download.
- **Evidence:**
  - `popup.html` exposes `Toggle Extended Layout`, `Copy ID - Title`, and `Copy as Markdown`.
  - `popup.js` uses `chrome.scripting.executeScript` to read task id/title and `window.__CU_LAYOUT_API__?.getTaskHref(id)`.
  - `content.js` owns task link discovery but has no export or full-field capture API.
  - `manifest.json` already declares `activeTab`, `scripting`, `storage`, `clipboardWrite`, and ClickUp host permissions.
- **Class re-check:** held. The missing capability is in the extension's page-observation/export layer, not the Atlas app or a backend API.

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| ClickUp API first | Adds auth/token/workspace handling and may prompt setup before each export unless a settings flow is built. Too much v1 scope. |
| DOM-only forever | Fastest, but may miss non-rendered fields; keep API fallback available if live evidence proves DOM capture insufficient. |
| Hybrid DOM plus API in v1 | More complete but forces API key/OAuth decisions before proving the browser page cannot satisfy the requirement. |
| Copy Markdown to clipboard instead of download | Existing extension already copies a Markdown link; this ticket specifically requires a downloaded file. |
| `chrome.downloads` API | Useful if object-URL anchor download fails, but requires the `downloads` permission. Start with Blob/object URL to avoid new permission warning. |

## 7. Solution and stress-test

- **Proposed solution:** add a popup export action that injects a collector into the active ClickUp task page, gathers task data from stable visible selectors/regions, formats it as original-ticket Markdown, and downloads it via Blob/object URL.
- **Solves the confirmed class:** yes, it uses the extension's existing active-tab/browser-page capability instead of a separate integration login.
- **Scale:** one active task at a time; no batch export or background queue.
- **Generalization:** right-sized. Create reusable collector/formatter/download helpers inside `popup.js`; do not add a framework or build system.
- **Fit:** matches existing extension conventions: plain MV3 files, popup-owned actions, `chrome.scripting.executeScript`, visible status, and page toast.
- **Adjacent issues:** duplicate copy logic exists in `content.js` and `popup.js`; note but do not refactor in v1 unless it blocks export.
- **Sufficiency:** covers Phase 0 ticket capture for the active ClickUp task. It will not capture comments/activity unless added later.
- **Feedback speed:** immediate: downloaded file can be opened and compared against the visible ClickUp task.
- **Happy-path story:** Dustin opens a ClickUp task, clicks the extension, chooses export, sees loading/success feedback, and receives `TASKID-original-ticket.md` containing title, metadata, description, constraints/context placeholders, and downstream artifact placeholders.

## 8. Assumptions ledger

- **Claim:** `activeTab` plus `scripting` is enough to inspect the active ClickUp page after popup invocation.
  - **Status:** confirmed
  - **Confirm/revise by:** Chrome docs and existing working `popup.js` extraction path.
- **Claim:** ClickUp Get Task can return Markdown description and custom fields.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** official ClickUp Get Task docs; actual API use would require token/workspace proof.
- **Claim:** Blob/object-URL anchor download works from the extension popup without `chrome.downloads`.
  - **Status:** open
  - **Confirm/revise by:** manual Chrome extension validation; fallback is `chrome.downloads` with manifest permission.
- **Claim:** visible DOM can supply required description and metadata.
  - **Status:** open
  - **Confirm/revise by:** Playwright/browser-loop inspection of live ClickUp task pages.
- **Claim:** PRDV-14055 is only a format reference.
  - **Status:** confirmed
  - **Confirm/revise by:** user clarification.

## 9. Validation plan

**Happy path**
- Open a ClickUp task with title, id, description, status, assignee, dates, tags/custom fields if present.
- Click extension popup export action.
- Observe loading state, then success toast/status.
- Confirm browser downloads `{ticket-id}-original-ticket.md`.
- Open file and verify title, id, URL, metadata, description structure, constraints/context placeholders, and downstream artifact placeholders.

**Negative paths**
- Non-ClickUp or non-task page: visible failure, no bad download.
- Task id/title missing: visible failure, no bad download.
- Description empty: generated Markdown states no description found without failing the whole export.
- Metadata absent: metadata section omitted or shows only captured fields.
- Filename has `#` or unsafe characters: file name is sanitized.
- Existing buttons still work: layout toggle, `Copy ID - Title`, and `Copy as Markdown`.

## 10. Decisions, recommendation and open variables

- **Decisions:**
  - Target repo is `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout`.
  - Use PRDV-14055 only as Markdown format reference.
  - V1 starts DOM-first and does not add token/OAuth UI.
  - V1 uses Blob/object-URL download first.
- **Recommendation:**
  1. Probe a live ClickUp task with browser-loop when an attachable session is available.
  2. Lock selectors/field extraction rules in the spec.
  3. Implement popup button, page collector, Markdown formatter, filename sanitizer, and download helper.
  4. Validate manually in Chrome and run syntax gates.
- **Sequencing and gates:** do not finalize selector-specific implementation claims until the live ClickUp DOM has been inspected. A generic fallback collector is acceptable, but the spec must name this residual risk if live proof remains unavailable.

### Open variables to collect

- [ ] Exact stable selectors/DOM regions for ClickUp description, metadata, and custom fields - owner: implementing agent with live browser access.
- [ ] Whether Blob/object-URL download is accepted from popup in the target Chrome setup - owner: implementing agent.
- [ ] Whether comments/activity are out of scope for the user long-term - owner: Dustin if this becomes a follow-up.

---

## 11. Plan - Next steps

### Handoff table
| Action | Owner | Done-when |
|--------|-------|-----------|
| Inspect live ClickUp task DOM | Implementing agent | Selector map recorded for title, id, description, status, assignees, dates, tags/custom fields |
| Write spec | Implementing agent | Spec locks DOM-first v1 and all open variables have accepted defaults or answers |
| Implement export | Implementing agent | Popup downloads `{ticket-id}-original-ticket.md` and existing buttons still work |
| Validate manually | Implementing agent | Downloaded file is inspected against a live ClickUp task |

### Checklist
#### Investigation
- [x] Report created
- [x] Coverage ledger created
- [x] Diagrams artifact created
- [x] Test plan seeded

#### Project Spec
- [ ] Lock selector strategy and fallback behavior
- [ ] Create project spec

#### Development
- [ ] Add popup export button and loading state
- [ ] Add DOM collector, Markdown formatter, filename sanitizer, and download helper

#### Testing and Validation
- [ ] Run `node --check popup.js`
- [ ] Run `node --check content.js`
- [ ] Run `node --check background.js`
- [ ] Reload unpacked extension and validate on a live ClickUp task

---

## 12. Definition of done

- [x] Class derived from instances and re-confirmed against root cause
- [x] Problem in one plain sentence
- [x] Named blocked instance
- [x] Date or trigger when it bites next
- [x] Wedge and why it is reusable
- [x] Acceptance criteria and non-goals locked
- [x] Alternatives recorded
- [x] Happy-path story
- [x] Metric that proves it works
- [x] Verdict and disposition stated
- [x] Open variables each have an owner
- [x] Tracked action with falsifiable done-when

---

## 13. Post-Investigation Addendum - Live DOM Proof

Date: 2026-07-20

After the user launched Chrome with `--remote-debugging-port=9222`, Playwright connected to the live ClickUp task at `https://app.clickup.com/t/43227262/PRDV-14055`.

Selector proof completed for the reference task:

| Field | Runtime structure |
| --- | --- |
| Task ID | `[data-test="task-view-task-label__taskid-button"]` |
| Title | `[data-test="task-title__text-area"]` |
| Task root | `[data-test="task-view-task-content__scrollable"]` |
| Description | `[data-test="task-editor-wrapper"] .ql-editor`; fallback `[data-test="task-editor"]` |
| Hero metadata | `[data-test^="task-field-label-icon__container-"]` closest `.cu-task-fields__row` |
| Custom fields | `[data-test="task-custom-fields__row"]` with `.cu-task-custom-fields__row-type` and `.cu-task-custom-fields__row-body` |
| Location | `[data-test="task-view-breadcrumbs__timl-list-item"]`; `[data-test="location-editable__location-title"]` |

Runtime collector proof returned id `PRDV-14055`, title `Make Upload Manager count up instead of down`, location `Product Development > Master Product Backlog > MBL LIST`, readable description Markdown, and 15 visible metadata rows. Formatter proof produced filename `PRDV-14055-original-ticket.md` with expected original-ticket sections.

Remaining validation: reload the unpacked extension in Chrome and validate the popup click/download plus existing copy/toggle behavior.
