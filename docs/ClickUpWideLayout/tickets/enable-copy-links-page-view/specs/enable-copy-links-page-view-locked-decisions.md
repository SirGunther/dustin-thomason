# Locked decisions — ClickUpWideLayout/enable-copy-links-page-view

> Full decision ledger for the Phase 3 probe/spec pass. The companion [spec](./enable-copy-links-page-view-spec.md) links here instead of duplicating the ledger.

## Question gates resolved without re-asking

### Question Gate 1

- **Proposed question:** Should the full ClickUp task page receive a new copy control?
- **Existing answer check:** Answered explicitly by the user: “Existing buttons only.”
- **Current behavior evidence:** `popup.html` already exposes `ID + title` and `Markdown link`; `content.js` injects no task-header control.
- **Recommendation:** Keep all visible UI unchanged.
- **Ask only if still unresolved:** No.

### Question Gate 2

- **Proposed question:** Which layer owns task ID, title, URL, and rendered context?
- **Existing answer check:** The approved recon locks `window.__CU_LAYOUT_API__.getTaskMeta()` as the provider.
- **Current behavior evidence:** `popup.js#findTaskMeta()` duplicates ID/title lookup while `content.js#getTaskHref()` already owns URL resolution.
- **Recommendation:** Centralize the four values in the injected content API and make the popup delegate.
- **Ask only if still unresolved:** No.

### Question Gate 3

- **Proposed question:** When is the current browser URL authoritative?
- **Existing answer check:** The approved recon locks the current `/t/...` route for rendered full-page task context and existing anchor/DOM resolution for panes.
- **Current behavior evidence:** Live `PRDV-16313` exposes full-screen markers and a `/t/...` URL; current code fails when the visible ID is absent from that route.
- **Recommendation:** Full-page task route first; preserve pane and legacy fallbacks; unknown contexts fail safely.
- **Ask only if still unresolved:** No.

### Question Gate 4

- **Proposed question:** Should either clipboard payload change?
- **Existing answer check:** The ticket/changelog and approved recon require exact existing formats.
- **Current behavior evidence:** `formatTaskCopy()` and `formatTaskMarkdown()` define the current plain/rich and Markdown contracts.
- **Recommendation:** Do not modify formatters or toast wording.
- **Ask only if still unresolved:** No.

### Question Gate 5

- **Proposed question:** What happens when task metadata is late or absent?
- **Existing answer check:** The reconciled story and approved recon preserve bounded retry and visible failure.
- **Current behavior evidence:** Popup retries eight times at 150 ms; content copy retries six times at 120 ms and both surface errors.
- **Recommendation:** Move the popup’s existing eight-attempt/150 ms metadata wait into the provider; return `null` afterward and preserve popup feedback.
- **Ask only if still unresolved:** No.

### Question Gate 6

- **Proposed question:** Is a backend/API or external spec review required?
- **Existing answer check:** The investigation rules out an API; this is a personal, local, non-Git extension with the user as sole product/spec owner.
- **Current behavior evidence:** Active-tab DOM and existing MV3 permissions supply all data; the implementation folder has no `.git` or external review surface.
- **Recommendation:** No backend/API. Record spec review as not applicable and deliver the canonical artifact directly to the user at handoff.
- **Ask only if still unresolved:** No.

## Locked-decision ledger

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | Keep `ID + title` and `Markdown link` as the only visible copy controls; add no ClickUp-page UI. | User clarification: “Existing buttons only”; report §§2, 4 | Rejects the original ticket’s proposed primary-header control and menu/button variants | UI and scope |
| LD-002 | Add async `window.__CU_LAYOUT_API__.getTaskMeta()` returning `{ id, title, url, context }` or `null`; popup metadata lookup delegates to it. | Approved recon; report §§5, 7 | Supersedes duplicated popup/content metadata ownership | Internal interface and data flow |
| LD-003 | Context values are `full-page`, `pane`, and `unknown`. A rendered full-page task on an `app.clickup.com/t/...` route uses `window.location.href`; pane preserves existing anchor/nearby-DOM lookup; unknown never receives an unconditional current-URL fallback. | Approved recon; live DOM; report §§5, 8 | Rejects unconditional `window.location.href` fallback and pane-only assumptions | Context precedence and failure modes |
| LD-004 | Preserve exact payload formatters, rich/plain clipboard fallback, toast text, and popup close behavior. | Existing `popup.js`; changelog; report §3 | Rejects payload cleanup or new copy semantics in this ticket | Clipboard contract |
| LD-005 | Preserve the popup’s bounded metadata timing by performing up to eight reads separated by 150 ms; return `null` when exhausted, with no metadata cache across task changes. | Existing `popup.js#findTaskMeta()`; approved test seed | Rejects indefinite observation, cached metadata, and silent stale copies | Retry and lifecycle |
| LD-006 | No ClickUp/backend API, manifest permission, background behavior, full-ticket export, layout, or theme change belongs to this ticket. | Manifest/background trace; user scope; report §§3, 6 | Rejects endpoint/auth work and adjacent refactors | Non-goals and neighbor protection |
| LD-007 | Add a red→green content resolver suite and focused popup runtime tests; finish with syntax, manifest, and loaded-extension full-page/pane proof. | Detection-gap finding; refined test plan | Supersedes reliance on syntax-only/manual confidence | Testing |
| LD-008 | External spec review is not applicable: ClickUpWideLayout is a personal local extension, the user is the sole product/spec owner, and there is no Git/shared-wiki review surface. The spec is delivered through the canonical ticket artifact and orchestration handoff. | Repository boundary; user approval of recon; orchestration record | Rejects fabricating a PR/reviewer workflow for a non-Git personal project | Review disposition |

## Open decisions

None. No decision is left as TBD, and every rejected path is recorded above.

## Risk-accepted decisions

None. Live browser validation is a completion gate, not deferred risk acceptance, so no future-development-concerns entry is required.
