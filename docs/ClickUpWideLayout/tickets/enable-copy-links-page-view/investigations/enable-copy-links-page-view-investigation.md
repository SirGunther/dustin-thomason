# Investigation Report: Copy links from full ClickUp pages

> **What this is:** the delivered results of the Phase 1 investigation. It records the findings, recommendation, evidence, and validation contract.
> **What this is not:** implementation approval or proof that the loaded extension already passes the new scenarios.

## Metadata

- **Status:** done
- **Disposition:** proceed with conditions
- **Date:** 2026-08-11
- **Owner:** ClickUpWideLayout
- **Location:** `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/investigations/enable-copy-links-page-view-investigation.md`
- **Ticket:** User-provided brief; no external ticket URL supplied
- **Domain:** software — MV3 browser extension
- **References / evidence:** `original-ticket.md`; `popup.js`; `content.js`; `background.js`; `manifest.json`; `tests/popup-markdown.test.mjs`; authenticated live DOM for `https://app.clickup.com/t/43227262/PRDV-16313`; prior `export-clickup-ticket-to-markdown` coverage ledger

---

## 0. Verdict (bottom line up front — written last, read first)

Proceed with conditions. The two existing popup copy controls can support both full-page and pane task contexts without new UI or a backend call, but task metadata ownership must move behind the injected content API and URL resolution must recognize an active full-screen `/t/...` route even when its route ID differs from the displayed custom ID. This is a viable, focused extension change; it is not yet implementation approval or runtime proof until the red→green resolver test, focused popup tests, syntax gates, and loaded-extension browser checks pass.

- **Strongest path:** add context-aware `getTaskMeta()` to `window.__CU_LAYOUT_API__`, make the popup delegate metadata lookup to it, and preserve all existing payload/clipboard/toast behavior.
- **Not yet proven / not approved:** a loaded unpacked extension has not yet copied both formats from the direct-route mismatch case and a pane after the change.

## 1. Problem class

- **Class the request assumed:** a pane-bound extraction service that needs a main-page controller or independent metadata endpoint.
- **Confirmed class:** a context-aware URL-resolution and metadata-ownership defect inside the existing MV3 extension.
- **Reframed?** yes — from **pane-only data access** to **shared context resolution**, triggered in Step 4 by the absence of pane state in `popup.js#findTaskMeta()`, the current URL/anchor contract in `content.js#getTaskHref()`, the export path’s existing current-URL fallback, and live full-screen selector proof.
- **What the confirmed class implies:** fix the existing injected content API and its consumer; do not add ClickUp-page controls, controller injection, authentication, or an HTTP endpoint.

## 2. Problem statement (the raw facts — collected before classification)

- **Named instances:** Dustin, using the ClickUpWideLayout popup on the directly opened task context that triggered this ticket, cannot reliably obtain a linked payload when the full-page route does not expose the displayed task ID. `PRDV-16313` was inspected live as a full-screen control instance: its selectors work and its custom ID appears in the URL, so that variant should already resolve.
- **One sentence:** the two existing copy actions can lose the active task URL on a directly opened ClickUp task whose route ID differs from the displayed task ID.
- **Distinct problems:** URL source selection is not explicitly context-aware; ID/title lookup is duplicated between popup and content code; the two link-copy runtime paths lack regression tests.
- **Urgency:** from 2026-08-11 onward, it bites on the next directly opened task URL using a non-matching internal route ID.
- **Wedge:** make one content-owned metadata provider choose the URL source from the rendered task context, then have both existing popup controls consume it. The provider is reusable across both formats and both task contexts.

### Problem Check

- **Asked:** make the existing capability work when users navigate directly to a task — *evidence:* “copy title and markdown-formatted links regardless of whether the user is in a pane or on the source page.”
- **Answered:** keep the existing controls and make their metadata resolver context-aware — *evidence:* “dynamically determine which copy mechanism should be used whenever the screen is present” and the later locked clarification “Existing buttons only.”
- **Should-ask:** which layer already owns task URL discovery, and which rendered context proves the current URL is authoritative? — *why:* it distinguishes a resolver defect from a new UI or backend capability.
- **Conflation:** the request combines extraction ownership, URL selection, proposed backend/API work, and a new header control; only the first two belong to the confirmed defect — *evidence:* “Decouple the link extraction service,” “Evaluate if ... an endpoint,” and “Add/Ensure a ‘Copy Link’ action button.”
- **Thin:** “title link” did not define its payload, and “primary header” did not distinguish the extension popup from ClickUp’s task header — *evidence:* “copy markdown and title links” and “primary header of the ClickUp page view.” Existing code plus user clarification resolve these as the established ID/title/URL payload and unchanged popup UI.
- **Off:** the named `copyLink` method and pane/sidebar component state do not exist in this repository, while the final UI clarification rejects new controls — *evidence:* “Audit the existing `copyLink` method” → “Existing buttons only.”

## 3. The contract (locked before any solutioning)

### Acceptance criteria

| Criterion | Status | What's needed to close it |
| --- | --- | --- |
| AC-1 — From a task’s own ClickUp URL, copy the established title-based value without reopening it | needs-proof | Red→green internal-route mismatch test plus loaded-extension full-page copy |
| AC-2 — From a task’s own ClickUp URL, copy the established Markdown heading link without reopening it | needs-proof | Focused popup payload test plus loaded-extension full-page copy |
| AC-3 — Each copied value identifies the active task and includes its URL when required | needs-proof | Context-provider unit cases for full-page, pane, unknown, and missing metadata |
| AC-4 — Existing outcomes remain available when the task opens as an overlay | needs-proof | Pane resolver regression test and loaded-extension pane check |
| AC-5 — Either existing copy outcome can complete from the directly opened task without reopening it | needs-proof | Both popup controls verified on the same active full-page task |

### Non-goals / out of scope

- No new control, menu, or injected UI in ClickUp’s task header; the user locked the existing two popup controls.
- No ClickUp API, OAuth/token flow, backend endpoint, or data-model change; active-tab DOM access already provides the required metadata.
- No change to full-ticket Markdown export/download, layout toggle, popup theme, or existing payload formats.
- No support for copying from non-task ClickUp pages; those must fail safely.

## 4. What changed since the request was created

- **Shifted from:** a pane-bound service plus new primary-header control and possible endpoint → **to:** context-aware metadata resolution behind the existing popup controls.
- **What that buys us:** a smaller fix aligned with the repository’s architecture, no extra UI, no authentication surface, and one owner for task metadata.
- **What it still needs to prove:** exact payload parity, safe failure on unknown contexts, pane regression safety, and loaded-extension behavior after reload.

## 5. Why it exists

- **Origin traced to:** `popup.js#findTaskMeta()` owns ID/title selection but delegates only URL lookup to `window.__CU_LAYOUT_API__.getTaskHref(id)`; `getTaskHref()` accepts the current URL only when it contains the displayed ID, then searches anchors/nearby DOM. A direct `/t/...` route using an internal ID and lacking a self-anchor returns `null` even though the current route is authoritative. The full-ticket collector already compensates with `getTaskHref(id) || window.location.href`.
- **Evidence:** `popup.js:58-90`, `popup.js:173-203`, `popup.js:220-239`, `content.js:119-151`, `content.js:303-385`, `background.js:127-134`, and the live `PRDV-16313` full-screen markers/selectors. See [the standalone diagrams](./enable-copy-links-page-view-diagrams.md) for the current and target control paths.
- **Contract alignment:** the injected content API is the existing authority for active-tab URL discovery; the popup should consume that authority rather than mirror DOM/context rules.
- **Detection gap:** `tests/popup-markdown.test.mjs` exercises presentation, theme, and full-ticket copy/export, but not `copy-task`, `copy-task-markdown`, or `getTaskHref()` context behavior.
- **Class re-check:** flipped from pane-bound access to context resolution. The observable acceptance criteria held; the wedge changed from new UI/provider injection to centralizing and correcting the existing provider.

## 6. Alternatives considered

| Alternative | Rejected because |
| --- | --- |
| Add only `|| window.location.href` in the popup | Leaves duplicated metadata ownership and can copy a non-task URL without a context gate |
| Add new ClickUp-header copy controls | Explicitly rejected by the user; duplicates existing UI and adds remount/accessibility complexity |
| Duplicate full-page logic in each popup handler | Allows the two formats and content API to drift again |
| Fetch task metadata from ClickUp/backend API | Unnecessary permissions/authentication, latency, and failure surface for data already rendered in the active tab |
| Reuse ClickUp’s native Copy Task ID control | It copies only the ID and cannot satisfy the established plain or Markdown link contracts |

## 7. Solution & stress-test

- **Proposed solution:** add a context detector and async `getTaskMeta()` to `window.__CU_LAYOUT_API__`; resolve full-page task routes from `window.location.href`, preserve pane anchor/DOM lookup, return `null` for unknown contexts, and make `popup.js#findTaskMeta()` call that provider. Keep all formatting and clipboard code unchanged.
- **Solves the confirmed class?** yes; one content-owned provider becomes authoritative for ID, title, URL, and context.
- **Contract/source-of-truth alignment:** the popup stops mirroring task selectors/context rules and consumes the same injected API already used for URL discovery.
- **Affected surfaces and completeness:** two popup listeners (`copy-task`, `copy-task-markdown`), `popup.js#findTaskMeta()`, `content.js#copyIdAndTitle()`, `content.js#getTaskHref()`, background/popup content injection, and focused Node tests. `rg` found no other `copyIdAndTitle` callers or `findTaskMeta` implementations.
- **Protect the neighbors:** full-ticket collector/formatter, download flow, theme, layout toggle, popup close timing, clipboard fallback, toast wording, and pane anchor discovery remain unchanged and get regression coverage where executable.
- **Scale:** one active task DOM and bounded retries; no volume-dependent work or network call.
- **Generalization:** the provider covers existing full-page/pane variants only; extracting a larger framework or ClickUp API client would be overreach.
- **Fit:** follows the existing MV3 `chrome.scripting` plus `window.__CU_LAYOUT_API__` architecture and keeps the no-build test harness.
- **Adjacent issues:** the unused legacy copy method and older export artifact wording are not required for this fix and remain out of scope.
- **Sufficiency:** covers both established copy formats and both task-opening contexts without changing interaction design.
- **Feedback speed:** Node tests and syntax checks fail immediately; loaded-extension proof is available immediately after reload in the authenticated browser.
- **Happy-path story:** a ClickUp user directly opens a task, opens the existing extension popup, chooses either current Header copy action, and receives the correct active-task payload and success toast without reopening the task or calling an API.

## 8. Assumptions ledger

- **Claim:** the established ID/title selectors work in full-screen task view.
  - **Status:** confirmed
  - **Confirm/revise by:** authenticated live DOM on `PRDV-16313` found `[data-test="task-view-task-label__taskid-button"]` and `[data-test="task-title__text-area"]` with visible values.
- **Claim:** a full-page `/t/...` route is authoritative even when its route ID differs from the displayed custom ID.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** request behavior, ClickUp route shape, existing export fallback, red→green unit fixture, then loaded-extension proof when such a route is available.
- **Claim:** existing pane behavior can continue using anchor/nearby-DOM discovery.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** existing `getTaskHref()` implementation and prior coverage; focused unit fixture plus loaded-extension pane regression still owed.
- **Claim:** no backend/API is required.
  - **Status:** confirmed
  - **Confirm/revise by:** manifest permissions, active-tab scripting, live DOM values, and existing full-ticket export all provide the data locally.
- **Claim:** the user wants no new ClickUp-page UI.
  - **Status:** confirmed
  - **Confirm/revise by:** explicit user decision “Existing buttons only.”
- **Claim:** metadata-unavailable behavior should remain bounded retry followed by visible error.
  - **Status:** confirmed
  - **Confirm/revise by:** existing popup/content behavior and the approved recon plan.

## 9. Validation plan

**Happy path**

- Run a red→green unit fixture with visible ID `PRDV-12345`, full-screen context, and current URL `/t/43227262/86abc123`; `getTaskMeta()` must return the current URL.
- Exercise both current popup controls against that metadata and assert the exact plain and Markdown payloads.
- Exercise pane metadata with a matching anchor and assert the existing URL/output remains unchanged.
- Reload the unpacked extension and repeat both copy actions on one directly opened task and one pane task, observing the clipboard and toast.

**Negative paths**

- Missing ID/title after the bounded retry returns `null`, shows the existing error, and writes nothing.
- A non-task page with no matching task anchor must not use its current URL.
- Clipboard rejection uses the established visible failure toast.
- Delayed metadata that appears within the retry window succeeds once without stale-task copying.
- SPA/task remount reads metadata at click time, so a prior task cannot leak into the next task.
- Full-ticket export, layout toggle, theme, popup markup, and content pre-injection pass their existing regression gates.

## 10. Decisions, recommendation & open variables

- **Decisions:** existing two popup controls only; content API owns metadata/context; full-page route wins only in a rendered full-page task context; pane retains current anchor/DOM logic; payloads, retries, clipboard fallback, toasts, and unrelated features remain unchanged; no backend/API.
- **Recommendation:** specify the internal API contract and tests in Phase 3, prepare an implementation plan in Phase 4, then implement provider → popup delegation → focused tests → serial verification → loaded-extension manual proof.
- **Sequencing & gates:** do not edit product code until the spec is accepted and reviewed and the implementation plan is approved. Do not call implementation complete until the direct-route mismatch test is red→green and both live task contexts are checked after extension reload.

### Open variables to collect

None. All discoverable facts were resolved in §8 and the user locked the only product choice. A live internal-ID route and loaded-extension clipboard run are validation gates, not decisions.

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
| --- | --- | --- |
| Lock the internal metadata/context contract and test assertions | Phase 3 spec owner | Accepted story has no open questions; spec names provider return shape, context precedence, unchanged payloads, and safe failures |
| Prepare implementation sequence | Phase 4 plan owner | Every code touch and gate maps to a test-plan scenario |
| Implement the provider and popup delegation | ClickUpWideLayout implementer | Focused diff contains no new UI/backend work and exact resolver/payload tests pass |
| Validate loaded extension | Implementer + user browser | Both current buttons copy correct values from direct full-page and pane tasks after reload |

### Checklist

#### Investigation

- [x] This report (Sections 0–10)

#### Project Spec

- [x] Draft open questions / unknowns — none remain after evidence and user clarification
- [ ] Create and accept project spec

#### Development

- [x] Create new branch — not applicable; extension folder is not a Git repository
- [ ] Begin implementation after spec/review/prep gates

#### Testing & Validation

- [ ] Execute the refined test plan and loaded-extension validation

#### Deploy & PR

- [ ] Record final diff/evidence; PR is not applicable unless the implementation folder becomes a Git repository

#### Ticket Closeout

- [ ] Walk every acceptance criterion against executed evidence and finalize the Why doc

---

## 12. Definition of done (investigation gate)

- [x] Class derived from instances, re-confirmed against root cause, and reframing justified
- [x] Problem Check recorded with quote-grounded flags
- [x] Problem stated in one falsifiable sentence
- [x] Named blocked instance recorded
- [x] Immediate trigger/date recorded
- [x] Reusable wedge identified
- [x] Acceptance criteria and non-goals locked before the solution
- [x] Alternatives and rejection reasons recorded
- [x] Thirty-second happy path recorded
- [x] Exact payload/runtime gates identify success and provide immediate feedback
- [x] Verdict and disposition stated
- [x] Discoverable facts resolved in §8; no genuine decisions remain in §10
- [x] Handoff actions have falsifiable done-when conditions
