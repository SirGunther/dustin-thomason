# Testing implementation — ClickUpWideLayout/enable-copy-links-page-view

> Companion to [enable-copy-links-page-view-test-plan.md](./enable-copy-links-page-view-test-plan.md). The scenarios stress-tested and what came of each — for other developers. PR-comment content; never a code comment. Living document.

## Scenarios stress-tested

### Scenario 1 — A directly opened task displays a custom ID that is absent from its internal-ID URL

- **Why it matters:** this is the reported failure; a correct title with a missing link still makes both established copy outcomes incomplete.
- **Covered by the plan?** yes.
- **Result:** held after implementation, both in the Node DOM harness and against the authenticated full-screen `PRDV-16313` page with a temporary internal-ID route.
- **Change:** `content.js` — observed ID-dependent current-URL acceptance → expected active full-page `/t/...` URL → implemented context-aware `getTaskMeta()` and full-page route precedence.

### Scenario 2 — A task remains open in a pane and its URL must come from ClickUp's rendered links

- **Why it matters:** fixing direct pages must not turn a workspace/list URL into a copied task URL or regress the established pane flow.
- **Covered by the plan?** yes.
- **Result:** held for direct matching anchors, nearby-DOM associated anchors, and a second pane task after SPA navigation.
- **Change:** `content.js` — preserved anchor and nearby-DOM discovery after the full-page-only current-route rule; metadata is read on every invocation rather than cached.

### Scenario 3 — Both existing popup controls must retain their exact contracts

- **Why it matters:** the change is a resolver correction, not a formatter or UI redesign.
- **Covered by the plan?** yes.
- **Result:** held. Plain output is exactly `ID - title` plus a newline and URL; Markdown output is exactly `# [title - ID](url)`. Existing success toasts and popup closing also held.
- **Change:** `popup.js` and `tests/popup-markdown.test.mjs` — removed popup-owned selector/retry logic and delegated one metadata request to the content API without changing either formatter or control.

### Scenario 4 — Missing metadata, an unrelated page, or a blocked clipboard must fail visibly and safely

- **Why it matters:** an unrelated current URL or stale task would be worse than returning no link.
- **Covered by the plan?** yes.
- **Result:** held. Unknown non-task context returned `url: null`; eight failed metadata reads returned `null`; missing metadata showed the established task-details status; rejected rich/plain clipboard writes showed the established blocked toast and closed normally.
- **Change:** `content.js` and focused tests — current-URL fallback is limited to ClickUp task routes and full-page context; bounded retries remain eight reads at 150 ms with no cache.

### Scenario 5 — Neighboring popup behavior must remain intact

- **Why it matters:** the popup also owns full-ticket copy/export and theme behavior.
- **Covered by the plan?** yes.
- **Result:** held in automated coverage; full-ticket copied Markdown still equals exported Markdown, clipboard failure feedback remains shared, theme persistence still works, all scripts parse, and the unchanged manifest parses.
- **Change:** none outside task metadata delegation and focused test coverage.

### Scenario 6 — The authenticated browser is available but the unpacked extension is not loaded

- **Why it matters:** live DOM/provider proof is not the same as clicking the actual extension popup and pasting its clipboard output.
- **Covered by the plan?** no — newly uncovered during execution.
- **Result:** follow-up in Phase 6 manual review; it did not drive a product-code change.
- **Change:** none. Phase 5 records the live provider proof separately and does not claim loaded-popup validation.

## PR comment (ready to paste)

Stress-tested the direct full-page route mismatch, existing pane anchor/nearby-DOM resolution, pane SPA task changes, both exact popup payloads, bounded retry/no-cache behavior, unrelated-page safety, missing-metadata feedback, blocked clipboard feedback, and neighboring full-ticket/theme behavior. The final automated gate passes 18 tests; JavaScript syntax and the MV3 manifest also pass. An authenticated live ClickUp proof on `PRDV-16313` returned the current URL for both its normal route and a temporary internal-ID mismatch route while adding no page UI. The authenticated Chrome instance did not have the unpacked extension loaded, so actual popup clicking/pasting and pane interaction remain the explicit Phase 6 manual-review step rather than being overstated here.
