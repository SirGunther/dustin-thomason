# Test plan — Jaimie/shareplane-modularize-availability

> Seeded from [shareplane-modularize-availability-investigation.md](../investigations/shareplane-modularize-availability-investigation.md) §9 on 2026-07-23. Refined by [spec](../specs/shareplane-modularize-availability-spec.md) on 2026-07-23 (LD-001…LD-006).

Status: refined

## Scope and surfaces under test

- **Refactor:** URL builders (`urlForSite`/`buildUrl`, `combinedUrlForSite`/`buildCombinedUrl`) must produce byte-identical output after modularization. Surfaces: single preview, `openAllLists`, bulk rows, combined view, `openAllListsBulk`.
- **Availability feature:** `sharepoint.js` authenticated `_api` read + parse; per-list badges across single + bulk + all-lists; graceful failure states.
- **Delivery context:** whichever of extension / SharePoint-page is chosen (D2).

## Happy path
- [ ] HP-1 (refactor): same list + Title as today → built single URL is byte-identical to the pre-refactor URL.
- [ ] HP-2 (refactor): same titles → combined URL (`useFiltersInViewXml=1&FilterFields1=Title&FilterValues1=...%3B%23...`) byte-identical.
- [ ] HP-3 (feature): logged-in user, known-existing Title in OJB → `_api $filter` returns 1 item → badge "found / 1".
- [ ] HP-4 (feature): "all lists" → per-list badge (found in OJB, not in Archive) for a Title present in one list only.
- [ ] HP-5 (LD-003 count): `621571` → OJB badge "1 found", Archive badge "2 found" (real counts via `$inlinecount`, not truncated). `627259` → OJB "not here", Archive "5 found".
- [ ] HP-6 (LD-005 single auto): typing a number in single mode auto-runs the count after ~400ms debounce (no button); a single keystroke does not fire a call per character.
- [ ] HP-7 (LD-002 F2 build gate): the built extension, loaded with no stale Chrome on the profile, returns OJB:1/Archive:2 for `621571` — **the executable proof of F2**.

## Negative paths
- [ ] NP-1: unknown Title → `_api` returns 0 → "not found" badge, **no error/exception**.
- [ ] NP-2: expired/absent 365 session → 401/403 → visible "sign-in expired, open SharePoint and retry"; no silent blank, no hang.
- [ ] NP-3: local `file://` script fetch to `_api` → CORS-blocked → tool does not hang; degrades to open-tab with a visible note (confirms F4).
- [ ] NP-4: throttle (HTTP 429) or 5,000-item threshold → visible warning; bulk uses batching, not N single calls (ties to D5).
- [ ] NP-5: wrong filter field (F3) → 0 results for a Title known to exist → "check field mapping" signal, not a false "not found". (F3 already confirmed: Title is the field.)
- [ ] NP-6 (LD-006 cap): bulk paste of >~30 titles → visible "split into smaller batches" warning; the check does not silently return partial counts.
- [ ] NP-7 (LD-005 bulk): bulk mode does NOT auto-fire on paste — it waits for the "Check availability" button.

## Edge cases
- [ ] EC-1: bulk with duplicates → dedupe preserved (current `parseTitles` behavior) before availability check.
- [ ] EC-2: Title with special chars / spaces / apostrophe → correct OData `$filter` escaping (`'' ` for apostrophes) and URL encoding.
- [ ] EC-3: list names with double-spaces ("VUL  Job Suggestions", custom OJB view) → `getbytitle` resolves the exact list title.
- [ ] EC-4: VUL availability (list not spike-tested) → `getbytitle('VUL  Job Suggestions')` returns results or a visible per-list error, never a silent blank.
- [ ] EC-5: batched `$filter` OR-chain stays under SharePoint's OR-clause limit for the ~30 cap (no query-threshold error).

## Test map
| Repo | Suite | Asserts |
| --- | --- | --- |
| Jaimie/Shareplane (no harness yet) | url-builder unit tests (to add) | byte-identical single + combined + all-lists URLs |
| Jaimie/Shareplane | sharepoint.js parse tests (to add) | 0/1/N item parsing; error-shape handling |
| — | manual/Playwright spike | F1–F4 live-context reads |

## Gates
| Gate | Command |
| --- | --- |
| audit | n/a — no `package.json` (loose folder); revisit if a build/test harness is introduced |
| lint | n/a — same; revisit if tooling added |
| tests | to be defined (candidate: a minimal Node/`vitest` harness for the pure URL-builder + parser, or a self-testing HTML page) — decision in Phase 3/4 |

## Results log (filled at execution)
| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| 2026-07-23 | F1 same-origin `_api` read | `node spike-sharepoint-api.mjs` (Playwright/CDP, auth Chrome) | OJB list, same-origin tab | PASS — ok:true/200, count 3 real items | — |
| 2026-07-23 | F3 `$filter=Title eq '000001'` | same | OJB | PASS — count 1 exact; Title is the field (zero-padded 6-char) | Input must match exact Title format (pad) |
| 2026-07-23 | NP-1 missing value | same | OJB | PASS — count 0, no error | — |
| 2026-07-23 | F4 file:// fetch to `_api` | same | file:// origin tab | PASS (as expected: blocked) — "Failed to fetch" (CORS) | Local file dead for in-tool parse |
| — | F2 extension cookie-fetch | Stage 2 (pending) | chrome-extension origin | NOT RUN | Gates extension delivery model |
