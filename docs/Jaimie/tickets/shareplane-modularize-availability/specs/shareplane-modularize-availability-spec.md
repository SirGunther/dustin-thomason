# Spec — SharePoint Shareplane: Modularize + Record-Availability Lookup

> Companion: [investigation](../investigations/shareplane-modularize-availability-investigation.md) · [locked decisions](./shareplane-modularize-availability-locked-decisions.md) · [test plan](../testing/shareplane-modularize-availability-test-plan.md) · [diagrams](../investigations/shareplane-modularize-availability-diagrams.md) · [concerns](../shareplane-modularize-availability-future-development-concerns.md)

## Problem → Requirement → Solution

- **Problem:** The tool is a single 789-line file mixing CSS + JS + HTML (hard to extend), and it builds SharePoint links **blind** — it cannot tell whether a record actually exists in a list before you open the link.
- **Requirement:** (1) A modular structure with a distinct data layer, without changing the existing URL-building output. (2) The tool must report, per configured list, **how many** matching records exist, reusing the user's existing 365 browser session with **no new auth method**, and degrade visibly when it can't.
- **Solution:** Refactor the monolith into HTML/CSS/JS modules with a `sharepoint.js` data-layer seam, and deliver it as an **MV3 browser extension whose icon opens a full-page dashboard** (extension-origin page authorized via `host_permissions` to read `_api` with the ambient session cookie). Availability = per-list count.

## Locked decisions (summary — full ledger in [locked-decisions](./shareplane-modularize-availability-locked-decisions.md))

| ID | Decision |
| --- | --- |
| LD-001 | Delivery = MV3 extension, full-page dashboard tab (not popup/file/SP-page) |
| LD-002 | F2 (cookie attaches to extension fetch) accepted; proven at build (Phase 5), fallback = SP-hosted page |
| LD-003 | "Availability" = per-list **count** (uses `$inlinecount`/sufficient `$top`) |
| LD-004 | Name = "SharePoint Shareplane"; rename file/extension |
| LD-005 | Single mode auto-checks (debounced ~400ms); bulk checks on-demand (button) |
| LD-006 | Bulk batches per-list `$filter`, caps ~30 titles, warns past the cap |

## 1. Folder hierarchy (target — new module structure)

```text
shareplane/                         (extension root — renamed from "SharePoint Lookup.html")
  manifest.json                     MV3; host_permissions; background; action (no default_popup)
  background.js                     service worker: chrome.action.onClicked → open dashboard tab
  dashboard.html                    full-page UI (markup extracted from the monolith)
  styles.css                        extracted from the monolith <style> (verbatim, then de-duped)
  src/
    config.js                       TENANT, SITES[], FILTER_FIELD (unchanged values)
    url-builder.js                  existing pure builders — FROZEN output (regression-tested)
    sharepoint.js                   NEW data layer: authenticated _api reads, parse, batch, errors
    availability.js                 titles → per-list counts (batching, cap, dedupe)
    ui.js                           rendering: badges, mode switch, warnings
    app.js                          wiring: events, debounce, entry point
  icons/                            extension icons (16/48/128)
```

Loading: `dashboard.html` uses `<script type="module" src="src/app.js">`; modules import each other (MV3 extension pages allow ES modules). `styles.css` linked, not inlined.

## 2. Modules / files (name → responsibility)

| File | Responsibility | Notes |
| --- | --- | --- |
| `manifest.json` | MV3 manifest | `host_permissions: ["https://planetdepos.sharepoint.com/*"]`; `background.service_worker`; `action` with **no** `default_popup`; name "SharePoint Shareplane" |
| `background.js` | Open the dashboard tab on icon click | `chrome.action.onClicked` → `chrome.tabs.create({url: chrome.runtime.getURL('dashboard.html')})` |
| `config.js` | Config constants | `TENANT`, `SITES` (name/site/list/view), `FILTER_FIELD="Title"` — values unchanged from the monolith |
| `url-builder.js` | The current URL builders | `urlForSite`, `buildUrl`, `combinedUrlForSite`, `buildCombinedUrl`, `parseTitles` — **byte-identical output** |
| `sharepoint.js` | Authenticated data layer | `countForList(site, list, titles[])` → per-list count via `_api getbytitle('list')/items?$filter=…&$inlinecount=allpages`; `credentials:"include"`; parses JSON; maps HTTP/error → typed result |
| `availability.js` | Orchestration | Given titles + selected/all lists → batched queries (cap ~30), dedupe, aggregate per-list counts; enforces LD-006 |
| `ui.js` | Rendering | Per-list count badges, "not here"/"N found"/error states, cap warning, mode switch |
| `app.js` | Wiring/entry | Debounced single-mode auto-check (LD-005), bulk on-demand button, existing copy/open behaviors preserved |

## 3. Delivery & auth (LD-001, LD-002)

- **Vehicle:** MV3 extension. Icon click opens `dashboard.html` in a full tab (extension origin `chrome-extension://…`), which inherits `host_permissions` and can `fetch` `_api` cross-origin with the session cookie attached — no CORS block (proven mechanism for extension pages; F1 proved the cookie read itself).
- **Auth:** ambient 365 session cookie; **no login/redirect in the tool**. If the session is absent/expired, `_api` returns 401/403 → the tool shows "SharePoint session expired — open SharePoint, sign in, retry" (the user re-auths in a normal tab; nothing the extension handles).
- **F2 gate:** the first executable step of Phase 5 is to load the built extension (with **no stale Chrome on the debug profile**) and confirm a `621571` read returns OJB:1 / Archive:2. If it fails → fall back to the SharePoint-hosted page (F1 proven); only `sharepoint.js`'s fetch context changes.

## 4. Feature behavior

- **Availability = per-list count** (LD-003). For the selected list (single) or every configured list (all-lists / bulk), show `list: N found` or `not here`. Use `$inlinecount=allpages` (or a `$top` above expected duplicates) so the count is real, not truncated.
- **Single mode (LD-005):** debounce ~400ms after input; auto-run the count for the selected list (and optionally all lists); render inline badges. Existing copy/open link actions unchanged.
- **Bulk mode (LD-005, LD-006):** explicit "Check availability" button. Batch the pasted titles into per-list `$filter` queries (OR across titles, chunked), **cap ~30 titles/check**, and show a visible "split into smaller batches" warning past the cap (mirrors the existing URL-length warning). Dedup via existing `parseTitles`.
- **Input matching:** availability filters on the **same exact value** the links already use (`Title eq '<value>'`), keeping availability consistent with link-building. Note (from spike): real Titles are zero-padded 6-char (`"000001"`); the user's real numbers are already 6-digit, so exact match suffices. Optional zero-pad normalization is an enhancement, not required (recorded as a minor item, not blocking).

## 5. Preserve existing behavior (regression — AC1)

`url-builder.js` must produce **byte-identical** URLs to the current monolith for the same inputs across single, combined, and all-lists. All existing UI (list picker, mode toggle, copy/open, "open in all lists", combined view, warnings, theming, keyboard Enter-to-copy) is preserved. This is the protect-the-neighbors surface.

## 6. Error / degradation states

| Condition | Behavior |
| --- | --- |
| 401 / 403 (no/expired session) | Visible "session expired — sign in and retry"; no silent blank |
| Network error / fetch throw | Visible "couldn't reach SharePoint"; badges show error, not "not here" |
| HTTP 429 / list-view threshold | Visible throttle/limit warning; bulk already batched + capped (LD-006) |
| Over the ~30 cap (bulk) | Visible "split into smaller batches" warning |
| List name mismatch (`getbytitle` 404) | Visible per-list error (guards the VUL two-space / custom-view list names) |

## 7. Testing

See the [refined test plan](../testing/shareplane-modularize-availability-test-plan.md): URL-builder byte-identical regression; per-list count happy path; auth-expired, throttle, cap, and list-name-mismatch negatives; VUL two-space edge; F2 build-time proof.

## 8. Naming (LD-004)

Product/extension name: **"SharePoint Shareplane"**. Extension folder `shareplane/`; manifest `name`. The old single file `SharePoint Lookup.html` is superseded by the extension (the original file is preserved until the extension is proven, then archived).

## Sections N/A (client-side extension — no backend)

- **New entities / Modified entities / Migrations / Migration classes / DTOs / Projections:** N/A — no backend, no database, no server API surface. The tool is a client-side extension reading SharePoint's existing REST API read-only.
- **HTTP surface (authored):** N/A — consumes SharePoint's `_api` (GET only); creates no endpoints.
- **Authorization:** N/A beyond reusing the user's existing SharePoint permissions (read-only); no new roles/guards.
