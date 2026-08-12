# Phase 1 Recon and Plan — Copy Links from Full ClickUp Pages

## Summary

Proceed with a focused context-resolution fix. Keep the existing `ID + title` and `Markdown link` popup controls unchanged; add no ClickUp-page controls and no backend/API dependency.

The confirmed problem is not pane-scoped ID/title extraction. It is duplicated metadata ownership plus URL resolution that assumes the displayed task ID appears in the current URL or a matching anchor. Full task URLs using an internal ClickUp ID can therefore return no link.

## Findings and Locked Decisions

- Live full-screen proof on `PRDV-16313` confirmed the existing ID/title selectors and full-screen markers work.
- The current URL succeeds when it contains the visible custom ID, explaining why this defect affects only some direct task URLs.
- `popup.js` owns the buttons and formatting; `content.js#getTaskHref()` owns URL lookup. No `copyLink` method or backend metadata provider exists.
- Centralize task metadata resolution in `window.__CU_LAYOUT_API__.getTaskMeta()`, returning `{ id, title, url, context }`.
- Detect context as `full-page`, `pane`, or `unknown`:
  - Full-page task route: use the current `/t/...` URL even when it does not contain the displayed custom ID.
  - Pane/overlay: preserve anchor and nearby-DOM link discovery.
  - Unknown/non-task context: preserve safe failure rather than copying the wrong URL.
- Preserve exact outputs:
  - Plain: `ID - title`, followed by the URL.
  - Markdown: `# [title - ID](url)`.
- Preserve retry timing, clipboard fallback, toast feedback, popup closing behavior, full-ticket export, layout toggle, and theme behavior.
- User clarification supersedes the ticket’s proposed new primary-header control: existing popup buttons are the only UI surface.

## Investigation Reconciliation

- Problem class: context-aware URL resolution and metadata ownership defect in an MV3 extension.
- Backend/API: ruled out; active-tab scripting and the rendered task DOM already provide the required data.
- Detection gap: existing tests cover popup presentation and full-ticket Markdown, but neither existing header-copy runtime path nor direct-route mismatch behavior.
- Story changes staged for Phase 2:
  - Resolve “title link” as the established ID/title/URL payload.
  - Resolve supported contexts as full-screen task routes and existing pane/sidebar variants.
  - Resolve unavailable metadata through the established retry-and-error-toast behavior.
  - Keep the five acceptance criteria unchanged; no story split.
- Why-log course change: discard injected ClickUp-header UI after the user locked “existing buttons only.”
- Coverage rows staged for the popup copy flow, content metadata service, background injection/manifest, test gap, and live full-screen DOM proof. Baseline commit remains `n/a` because the extension folder is not a Git repository.

## Test Plan Seed

- Red→green: visible ID `PRDV-12345` with direct URL `/t/43227262/86abc123` resolves the current URL in full-page context.
- Full-page custom-ID URL continues to resolve correctly.
- Pane context continues to resolve a matching task anchor.
- Non-task pages and missing metadata do not copy an unrelated URL.
- Both existing popup buttons produce their exact established plain and Markdown payloads.
- Loading retries and clipboard failures retain visible error feedback.
- Existing full-ticket copy/export, layout toggle, theme, and pane behavior remain unchanged.
- After reloading the unpacked extension, validate both copy buttons on a direct full-page task and a pane task through the authenticated browser session.

## Phase 2 Working-Mode Actions

1. Send the explicitly authorized Phase 0 hook and deferred Phase 1 hook.
2. Mark Phases 0–1 done and Phase 2 in progress; save this approved recon plan verbatim.
3. Materialize the story reconciliation, Phase 1 why-log, investigation report, coverage ledger, diagrams, and seeded test plan.
4. Stage the empty PR-draft shell and append the Phase 2 changelog session entry.
5. Run the orchestration artifact gate, send the Phase 2 hook, and auto-advance to Phase 3.
