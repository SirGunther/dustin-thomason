# Spec — Copy links from full ClickUp pages

Project: ClickUpWideLayout  
Ticket: `enable-copy-links-page-view`  
Story: [Copy task links in any context](../stories/enable-copy-links-page-view-job-story-01-copy-task-links.md)  
Investigation: [Copy links from full ClickUp pages](../investigations/enable-copy-links-page-view-investigation.md)  
Decision ledger: [Locked decisions](./enable-copy-links-page-view-locked-decisions.md)

## Problem

The existing popup can read the visible task ID and title from a directly opened task, but its shared URL resolver accepts the current location only when the displayed ID appears in that URL. A valid full-page task route using ClickUp’s internal ID can therefore leave both existing link-copy outcomes without the active task URL. Metadata rules are split between popup and content code, so the contexts can drift.

## Requirement

The existing two popup Header copy outcomes must satisfy the accepted story’s [five acceptance criteria](../stories/enable-copy-links-page-view-job-story-01-copy-task-links.md#acceptance-criteria) in full-page and pane task contexts. The change must preserve all visible UI, exact payloads, failure feedback, and named neighboring behaviors.

## Solution

Make the injected content API the single metadata authority. It detects the rendered task context, performs the existing bounded ID/title wait, resolves the correct URL with context-specific precedence, and returns one serializable metadata object. The popup asks that provider for metadata, then continues using its current formatters, clipboard writer, toast helper, and close flow.

## Locked Decisions From Q and A

The full evidence, supersessions, and rejected paths live in the [locked-decision ledger](./enable-copy-links-page-view-locked-decisions.md).

| Decision | Source | Implementation consequence |
| --- | --- | --- |
| Existing popup controls only | LD-001 | No `popup.html`, popup styling, or ClickUp-page UI addition |
| Content API owns task metadata | LD-002 | Add `getTaskMeta()` and replace popup DOM lookup with one API call |
| Context-specific URL precedence | LD-003 | Full-page task route uses current URL; pane keeps legacy discovery; unknown fails safely |
| Clipboard contract frozen | LD-004 | Existing formatters, payload bytes, feedback, and close behavior remain |
| Bounded uncached reads | LD-005 | Eight attempts at 150 ms; no stale metadata storage |
| Neighbor/API scope frozen | LD-006 | No backend, manifest, background, export, layout, or theme behavior change |
| Regression proof required | LD-007 | New resolver suite, focused popup tests, serial gates, live browser proof |
| Review not applicable | LD-008 | Deliver this local spec directly; no fabricated PR/reviewer step |

## Internal interface

Add this method to the existing injected API:

```js
window.__CU_LAYOUT_API__.getTaskMeta(): Promise<{
  id: string,
  title: string,
  url: string | null,
  context: "full-page" | "pane" | "unknown"
} | null>
```

The interface is internal to the extension’s isolated content-script world. It is not an HTTP API and introduces no persisted schema.

### Metadata read

1. On each attempt, query `[data-test="task-view-task-label__taskid-button"]` and `[data-test="task-title__text-area"]`.
2. Read trimmed ID text and title `value`, falling back to title text content only when needed.
3. If either value is absent, wait 150 ms and retry, for at most eight attempts total.
4. When both exist, detect context and resolve the URL at that moment; do not cache across clicks or SPA navigation.
5. Return `null` after the final unsuccessful attempt.

### Context detection

- `full-page` when a rendered `[data-test="task-view__mode--full-screen"]` exists or `[data-test="task-view__container"]` carries `full-screen`.
- `pane` when the task container carries `compact-mode`, `inside-right-sidebar`, or `sidebar-mode`.
- `unknown` otherwise.

Only rendered task structure participates; the provider must not infer a task solely from an arbitrary ClickUp URL.

### URL precedence

1. In `full-page`, if `window.location` is on `https://app.clickup.com/t/...`, return `window.location.href` even when it does not contain the displayed custom ID.
2. Otherwise preserve the legacy check that returns the current URL when it contains the normalized displayed ID.
3. Preserve direct matching-anchor lookup.
4. Preserve nearby task-ID DOM/associated-anchor lookup.
5. Return `null` if no safe source exists.

The full-page branch must not rewrite, canonicalize, or strip query/hash data in this ticket; it preserves the current URL exactly, matching existing successful behavior.

## Popup data flow

1. Either existing Header control calls `copyCurrentTask(format)`.
2. Popup resolves the active tab and runs `ensureContentScript(tab.id)` unchanged.
3. `findTaskMeta(tab.id)` executes an async function in the extension’s isolated world that returns `window.__CU_LAYOUT_API__?.getTaskMeta() ?? null`.
4. Popup preserves existing missing-metadata and missing-Markdown-URL errors.
5. Popup passes the returned values to the existing formatter, clipboard helper, toast helper, and window-close path.

`content.js#copyIdAndTitle()` must delegate its metadata read to `getTaskMeta()` so the duplicate selector/retry implementation does not remain as a second authority. Its existing copy behavior otherwise stays unchanged.

## Failure modes

| Condition | Required behavior | Story trace |
| --- | --- | --- |
| ID/title never appears within bounded retry | Return `null`; popup displays existing task-details error; no clipboard write | AC-3, AC-5 |
| Full-page marker exists but location is not an `app.clickup.com/t/...` route | Do not use current URL unconditionally; continue safe legacy lookup | AC-3 |
| Pane has no matching anchor or nearby task link | Return `url: null`; plain copy preserves its existing no-link behavior and Markdown shows existing missing-link error | AC-3, AC-4 |
| Clipboard rich write fails | Preserve plain-text fallback | AC-1, AC-2, AC-4, AC-5 |
| All clipboard writes fail | Preserve existing visible clipboard-blocked feedback | AC-5 |
| Task changes through SPA navigation | Next click re-reads metadata; no prior task cache is available to leak | AC-3, AC-4 |

## Neighbor protection

- Full-ticket Markdown collection, formatting, copy, and Save As remain unchanged.
- Popup labels, order, styling, theme bootstrap/toggle, and height remain unchanged.
- Layout toggle messaging, background tab injection, storage state, and badge behavior remain unchanged.
- Existing pane URL discovery and content-script clipboard fallback remain available.
- `manifest.json` permissions and host scope remain unchanged.

## Folder hierarchy

N/A — no new production folder or module hierarchy. Focused tests may add `tests/content-links.test.mjs` beside the existing Node suite.

## New classes

N/A — plain JavaScript functions extend the existing content API; no class is introduced.

## New entities

N/A — browser-extension DOM metadata only; no persistence.

## Modified entities

N/A — no entity or schema layer exists.

## New migrations

N/A — no database.

## New migration classes

N/A — no database.

## New DTOs

N/A — the internal serializable metadata object is documented under Internal interface, not an HTTP DTO.

## New projections

N/A — no domain projection layer.

## HTTP surface

N/A — no network contract or ClickUp API call.

## Registries and module wiring

N/A — no framework registry. Existing background and popup script injection remains unchanged.

## Ports

N/A — the existing `window.__CU_LAYOUT_API__` object is the internal seam.

## Domain events / dispatchers / outbox

N/A — no server-side messaging.

## Domain exceptions

N/A — existing user-visible status/toast strings remain the failure contract.

## Authorization

N/A — existing `activeTab`, `scripting`, `clipboardWrite`, and ClickUp host permissions are unchanged.

## Tests

- Add `tests/content-links.test.mjs` with a Node VM/fake-DOM harness for context detection, direct internal-route mismatch, successful custom-ID URL, pane anchor fallback, unknown/non-task safety, and bounded retries.
- Extend `tests/popup-markdown.test.mjs` so `copy-task` and `copy-task-markdown` receive metadata from the content API and assert exact plain/Markdown values, error feedback, and unchanged close behavior.
- Run the refined [test plan](../testing/enable-copy-links-page-view-test-plan.md) serially, then reload the unpacked extension and execute the full-page and pane manual scenarios.

## Rollout and review

- Reload the unpacked extension after source changes; there is no deployment pipeline or migration.
- External spec review is not applicable per LD-008. The user is the sole product/spec owner and the canonical artifact is delivered at the orchestration handoff.
- Implementation remains gated on Phase 4 plan approval. Completion remains gated on automated and authenticated-browser proof.

## Open questions

None.
