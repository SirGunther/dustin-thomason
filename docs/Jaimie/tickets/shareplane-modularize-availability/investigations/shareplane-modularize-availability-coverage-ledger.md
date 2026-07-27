# Coverage ledger — Jaimie/shareplane-modularize-availability

**Consulted (2026-07-23):** grepped `docs/*/tickets/*/investigations/*-coverage-ledger.md` (2 found: PRDV-14055 upload-counter, ClickUp export-to-markdown) + `docs/**/*investigation*.md` (7) + all three rule sets. **No prior empirical coverage** of SharePoint `_api` cookie-fetch, cross-origin CORS behavior against SharePoint, Graph client-side fetch, OData `$filter` hand-queries, or extension-authenticated SharePoint fetch. **Reused:** `docs/power-platform-aws-investigation/` (same OJB lists; 5,000-item list-view threshold, ~300 calls/60s, `$filter`/delegation) for the scale analysis; OtterCopy MV3 `host_permissions`+service-worker-`fetch` as the extension precedent (token auth, not cookies); `runtime-browser-loop-spec-1.md:11` CORS reframe for the *testing* method. Reopen conditions: none triggered.

| Area | Items inspected | Findings | Status | Commit/evidence |
| --- | --- | --- | --- | --- |
| Current tool architecture | `SharePoint Lookup.html` lines 1–789 (full read) | Single file: inline `<style>` (3–338), markup (340–440), inline `<script>` (442–789). Zero network calls. | covered | full read |
| URL building (to preserve) | lines 451 `TENANT`, 452–470 `SITES`, 473 `FILTER_FIELD="Title"`, 527–545 builders | `urlForSite`/`buildUrl` (single, `FilterField1/FilterValue1`); `combinedUrlForSite`/`buildCombinedUrl` (bulk, `useFiltersInViewXml=1&FilterFields1/FilterValues1` joined by `%3B%23`). Pure string fns — regression target for byte-identical output. | covered | lines 527–545 |
| Link surfaces (blast radius) | `renderSingle` (577), `openAllLists` (614), `renderBulk` (635), `openCombined` (727), `openAllListsBulk` (741) | Availability must attach at all five surfaces, not single-only. | covered | enumerated |
| Filter field (contract) | line 473 `FILTER_FIELD="Title"`; spike `$filter=Title eq '000001'` → count 1 | **CONFIRMED** — `Title` is the field. New: real Titles are zero-padded 6-char (`"000001"`); `$filter` is exact-match. | covered (F3) | spike 2026-07-23 |
| Session-cookie `_api` read feasibility | spike over CDP (authenticated Chrome) | **F1 CONFIRMED** same-origin read ok:true/200/3 items; **F4 CONFIRMED** file:// → "Failed to fetch" (CORS-blocked). **F2 still open** (extension not yet tested). | covered (F1/F4); open (F2) | spike 2026-07-23 |
| Extension delivery precedent | `OtterCopy/manifest.json`, `modelProviderClient.js`, `background.js` | MV3, `host_permissions` cross-origin fetch works; but bearer/signed-URL auth, **no** `credentials:"include"`/cookie use anywhere. Cookie path is net-new. | covered | OtterCopy read |
| Scale limits (OJB lists) | `docs/power-platform-aws-investigation/{source-matrix,risk-register,decision-memo}.md` | 5,000-item list-view threshold; ~300 calls/60s; `$filter`/delegation on Operations Job Boards + Archive. | covered (reused) | prior ticket |
| Tenant hosting/custom-script permission | not inspected | Needed only for the SharePoint-page delivery option. | **not-yet-inspected (F5)** | Phase 3+ if D2=page |

## Not-yet-inspected frontier
- F5 tenant custom-script / page-hosting permissions (only if D2 = SharePoint-hosted page).
- Exact internal field names / indexed columns of the three lists (part of F3, needs `_api` access).
- Whether VUL "Job Suggestions" behaves like OJB for `$filter` (prior coverage named OJB + Archive, not VUL).
