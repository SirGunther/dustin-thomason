# Why these changes — ClickUpWideLayout/enable-copy-links-page-view

> The living “Why” of this ticket. Created Phase 1, updated every phase, finalized at close. High-level scenarios live in the testing-implementation doc; point-in-time classification lives in the [investigation report](./investigations/enable-copy-links-page-view-investigation.md).

## Problem class (the core — what are we actually solving?)

This is a context-aware URL-resolution and metadata-ownership defect in a browser extension: the same established copy outcomes must resolve the active task correctly whether ClickUp renders it directly or as a pane.

## The code at the root (what/where is the problem)

`content.js#getTaskHref()` only accepts the current URL when it contains the displayed task ID, then falls back to matching anchors and nearby DOM. `popup.js#findTaskMeta()` separately owns ID/title extraction. Together they leave directly opened task routes that use a different internal ID without a resolved link. The full trace is in the investigation report §5.

## The problems we're solving

- The active task URL can be unavailable to the two existing copy actions when a full-page route does not contain the displayed custom task ID.
- Task metadata extraction is split between the popup and injected content API, allowing page-context rules to drift.
- The exact defect path is not covered by the current Node test harness.

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-08-11 — [COURSE CHANGE]

- Obvious: both established copy formats must work from a directly opened task without reopening it as a pane.
- Not obvious: live full-screen proof on `PRDV-16313` showed ID/title selectors already work and its custom-ID URL already resolves; the failing class is the direct task route whose route ID differs from the displayed task ID.
- Assumptions logged: ClickUp’s full-screen marker and `/t/...` route identify the current task context; existing pane anchor discovery remains the correct fallback; bounded retry and toast behavior stay authoritative.
- What changed after learning more: the user clarified that the existing popup copy controls are the only desired UI surface.
- What was noise / discarded: the ticket’s proposed new primary-header action, `copyLink` method, main-page controller injection, and backend/API endpoint do not match the repository and are out of scope.
- Why this changes the solution: centralize context-aware metadata resolution in the existing injected content API and leave the UI unchanged.

### Phase 3 — 2026-08-11

- New understanding: no further class or scope change; the question-gate pass found every material answer already present in code, the approved recon, or the user’s explicit UI clarification.
- Decisions formalized: the content API owns `{ id, title, url, context }`, full-page and pane URL precedence is explicit, exact payloads and bounded retry are frozen, and no external spec review is owed for this personal non-Git extension.
- What was noise / discarded: no rejected Phase 1 path re-entered the spec.
- Why this preserves the solution: the spec adds implementation precision without widening the ticket beyond the five accepted criteria.

### Phase 4 — 2026-08-11 — [USER-DIRECTED SKIP]

- The user determined that a separate implementation-planning phase was unwarranted for this small, fully specified correction.
- Downstream consequence: no frozen implementation-plan artifact exists; Phase 5 used the accepted specification, refined test plan, and the in-chat checklist as its execution inputs.

### Phase 5 — 2026-08-11

- Implemented one metadata authority in `content.js`: bounded ID/title reads, explicit `full-page`/`pane`/`unknown` context, context-safe URL precedence, and no cache.
- `popup.js` now requests that service once instead of owning a second selector/retry loop; the content helper delegates to the same service.
- Self-review promoted context values to named constants and added symmetric direct-anchor/nearby-DOM plus failure-path coverage.
- Live authenticated proof confirmed the internal-route mismatch behavior on the rendered full-screen task and confirmed no ClickUp-page control was added.
- The dedicated Chrome instance lacked the unpacked extension, so loaded-popup interaction is carried honestly into Phase 6 rather than inferred from provider and harness results.

## Changes made — categorized

Count: 4 files in the extension folder.

- **Service ownership:** `content.js` adds `getTaskMeta()` and makes both existing content/popup callers consume it.
- **Context resolution:** `content.js` accepts the current `/t/...` URL only for the active full-page task (or the preserved task-route/custom-ID match), while pane/unknown contexts retain DOM-link lookup and safe `null` behavior.
- **Popup delegation:** `popup.js` removes duplicated task selectors/retry timing from `findTaskMeta()`; UI and formatters are unchanged.
- **Regression coverage:** `tests/content-links.test.mjs` adds resolver/context/retry/navigation coverage; `tests/popup-markdown.test.mjs` adds exact payload and failure feedback coverage.

## Why it shipped together

The service correction and tests are one atomic behavior change: the resolver enables the established controls, and the tests freeze both their new full-page path and existing pane/output contracts.

## Scope

Confined to ClickUpWideLayout task metadata/link resolution and focused tests. No new ClickUp-page controls, backend/API work, full-ticket export behavior, theme behavior, or layout-toggle behavior.

## Net

The ticket is a shared context-resolution correction, not a new UI feature.

## Verified

Verified by 18 passing Node tests, syntax checks for `popup.js`, `content.js`, and `background.js`, manifest parsing, and authenticated live full-page provider proof. Loaded-extension popup/pane interaction remains Phase 6 manual review because the debugging Chrome instance did not have the unpacked extension loaded.
