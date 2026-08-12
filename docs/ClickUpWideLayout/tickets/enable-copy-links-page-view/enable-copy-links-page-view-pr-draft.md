# Title

Enable copying task links from full ClickUp pages

## ClickUp

`enable-copy-links-page-view` (reported against `PRDV-16313` during live proof)

## Description

- Centralizes active-task metadata in `window.__CU_LAYOUT_API__.getTaskMeta()`.
- Detects `full-page`, `pane`, and `unknown` contexts.
- Uses the current ClickUp `/t/...` URL for a rendered full-page task even when the displayed custom ID is absent from the route.
- Preserves pane direct-anchor and nearby-DOM discovery and safe failure outside task context.
- Delegates both existing popup Header copy controls to the shared service without changing UI, payload formats, toasts, full-ticket export, layout, theme, background, or manifest behavior.

## Test Evidence

- `node --test tests/popup-markdown.test.mjs tests/content-links.test.mjs` — pass, 18 tests.
- `node --check popup.js`; `node --check content.js`; `node --check background.js` — pass.
- `Get-Content -Raw manifest.json | ConvertFrom-Json | Out-Null` — pass.
- Authenticated ClickUp CDP proof on visible `PRDV-16313` — pass for normal custom-ID route and temporary internal-ID mismatch route; original URL restored; no page copy control added.
- Loaded-extension popup/pane interaction — pending Phase 6 because the authenticated Chrome instance did not have the unpacked extension loaded.
- Package audit/lint — not available; this extension has no `package.json`.

## Commit hash

Not applicable. `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout` is a local unpacked-extension folder and is not a Git repository.

## Checklist

- [x] Scope matches the accepted story and spec.
- [x] Existing output formats and popup UI are unchanged.
- [x] Direct-page, pane, unknown, retry/no-cache, exact-payload, and feedback scenarios have automated coverage.
- [x] Self-review completed before the final installed-source gates.
- [x] Syntax, manifest, and automated tests pass.
- [ ] Phase 6 loaded-extension popup/pane manual review.

PR creation is not applicable because the implementation folder has no Git repository or remote. This draft is the handoff-equivalent review body.
