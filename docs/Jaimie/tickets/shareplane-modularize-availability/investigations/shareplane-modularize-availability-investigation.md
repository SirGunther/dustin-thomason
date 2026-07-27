# Investigation Report: SharePoint Shareplane — Modularize + Record-Availability Lookup

> Companion artifacts: [coverage ledger](./shareplane-modularize-availability-coverage-ledger.md) · [diagrams](./shareplane-modularize-availability-diagrams.md) · [test plan](../testing/shareplane-modularize-availability-test-plan.md) · [future-development concerns](../shareplane-modularize-availability-future-development-concerns.md)

## Metadata
- **Status:** investigating
- **Disposition:** proceed with conditions
- **Date:** 2026-07-23
- **Owner:** Dustin Thomason (proxying for Jaimie, the tool's user)
- **Location:** `docs/Jaimie/tickets/shareplane-modularize-availability/investigations/shareplane-modularize-availability-investigation.md`
- **Ticket:** personal project — no ClickUp; see `../original-ticket.md`
- **Domain:** software (client-side web tool + SharePoint REST)
- **References / evidence:** `C:\Users\dktho\OneDrive\PDProjects\Jaimie\SharePoint Lookup.html` (the whole tool, 789 lines, fully read); OtterCopy MV3 extension (`Browser Extensions/OtterCopy/manifest.json`); prior coverage `docs/power-platform-aws-investigation/` (OJB list OData limits); `docs/agents/runtime-browser-loop-spec-1.md`.

---

## 0. Verdict (bottom line up front)

Both asks are viable and, as the user intuited, **one coupled effort** — but the availability feature's viability is **gated on an empirical feasibility spike** that has not yet run. The refactor (de-monolith into HTML/CSS/JS + a data-layer seam) is low-risk and can proceed on its own reasoning. The availability feature's center of gravity is **not UI — it is the delivery model**: reusing the existing browser 365 session to read SharePoint's `_api` only works from an execution context the browser will let read that origin (a same-origin SharePoint-hosted page, or a browser extension with host permissions). A plain local `file://` double-click **cannot** do it (cross-origin `fetch` to `_api` is CORS-blocked), even though pasting the same URL in the address bar works — because that is a top-level navigation, not a script `fetch`.

- **Strongest path:** refactor with an explicit data-layer seam (`sharepoint.js`) so the feature drops into a slot; deliver the availability feature as an **MV3 browser extension** (primary candidate — reuses session via `host_permissions` + `credentials:"include"`, matches the user's "down and dirty," has the OtterCopy precedent), with a SharePoint-hosted/SPFx page as fallback.
- **Not yet proven / not approved:** F1–F4 (below) are unproven until the spike runs against a live authenticated browser. This is a viability finding, **not** a green light to build the feature. The delivery model (D2) must be chosen *after* the spike.

## 1. Problem class

- **Class the request assumed:** "add a feature + tidy the code" — an enhancement + refactor.
- **Confirmed class:** two classes, coupled — (a) refactor = **maintainability / architecture** (a monolith that resists extension); (b) feature = **a capability gated by execution context** (an authenticated read is only possible where the browser permits reading the SharePoint origin under the no-new-auth constraint).
- **Reframed?** **Yes**, for the feature — from "UI feature: show whether a record exists" to "**delivery-model decision**: where must this code run for a session-authenticated read to be possible at all?" Triggered at Step 2, hardened at Step 4 by the CORS/same-origin analysis. The UI (a per-list badge) is trivial once the data layer can fetch; the hard, load-bearing part is the execution context.
- **What the confirmed class implies:** we do not pick the delivery model on preference; we pick it on what the browser security model empirically permits with session-cookie auth. The refactor's module seam and the delivery model are the **same decision** — which is exactly why the user said the two asks "go hand in hand."

## 2. Problem statement

- **Named instances:** The tool's user (Jaimie, Planet Depos operations) builds SharePoint deep-links to records in the OJB / VUL / OJB-Archive lists under `/sites/JobSubmissionsPortal`. Two concrete pains: (1) the tool is a single 789-line file mixing CSS + JS + HTML — adding anything means editing a monolith; (2) links are built **blind** — the tool constructs a filtered-view URL for a record number without knowing whether that record exists in the chosen list, so a click can land on an empty filtered view.
- **One sentence:** "The Shareplane tool is a hard-to-extend single file, and it cannot tell me whether a record actually exists in a list before I open the link it builds."
- **Distinct problems (not merged):** (1) maintainability of the monolith; (2) blind links (no existence/availability check).
- **Urgency:** no hard date; enhancement-driven. Trigger: adding the availability feature is what forces the refactor now (they are coupled).
- **Wedge:** one authenticated `_api` `$filter` read that returns a parseable count for a single known Title using the existing session. Everything else (per-list badges, bulk, all-lists) is repetition of that one capability.

### Problem Check

- **Asked:** de-monolith + add availability lookups — *evidence:* "to abstract the code into multiple parts, there is css it looks like mixed with scripts, it's a monolith" and "creating api look ups to determine the availability of records int he mentioned sharepoint lists based ont he generated links."
- **Answered:** the mechanism and anchor are given — *evidence:* "the user would be logged in an auththenticated by their 365 creds" and "based ont he generated links."
- **Should-ask:** *what "availability" means*, *which field identifies a record*, *where the code runs* (delivery model), *how availability shows in the UI*, and *the tool's real name* — none are in the ticket text. *Why:* each decides query shape, UX, and feasibility.
- **Conflation:** "availability of records" bundles **existence** ("does a row with this Title exist") with **state** ("is the record in an available/open status"). Solving one does not answer the other — different query, different UX. — *evidence:* "determine the availability of records ... based on the generated links" (the links filter only by Title, which points at existence, but "availability" implies a status). → D1.
- **Thin:** "api look ups" (which API — SharePoint REST `_api` vs Graph?), "multiple parts" (which seams?), "availability" (defined above). — *evidence:* "creating api look ups", "abstract the code into multiple parts".
- **Off:** the session-reuse model contains a real tension — *evidence:* "the user would be logged in an auththenticated by their 365 creds" (a later clarification: "in the address bar you can run commands that return a payload ... The user is already auth'd throught he browser") → contradicts the delivery reality that a **script** `fetch` from a non-SharePoint origin to `_api` is CORS-blocked while an **address-bar navigation** to the same URL is not. The user's observation is correct; it just does not generalize from navigation to `fetch`. This gap is the core finding.

## 3. The contract

### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| AC1 Monolith split into HTML/CSS/JS with a distinct data-layer module; existing URL output byte-identical | needs-proof | Refactor + URL-builder regression test (byte-identical before/after) |
| AC2 Authenticated `_api` read via existing 365 session reports availability without a new login | needs-proof | Feasibility spike (F1/F2) proving a session-cookie `_api` read returns parseable data from the chosen context |
| AC3 Availability shown across single + bulk + all-lists, with graceful failure (auth-expired, network, throttle, 5k threshold) | gap | Data-layer error handling + UI states; surface enumeration §7 |
| AC4 No new auth method (no MSAL/OAuth/app-registration) | covered | Design constraint; session reuse only |
| AC5 Delivery model chosen is validated by the spike, not assumed | needs-proof | Spike resolves F1–F4; D2 decided in Phase 3 |

### Non-goals / out of scope
- No writes/updates to SharePoint (read-only availability).
- No MSAL / OAuth / app registration / server / backend.
- No SharePoint schema or column changes.
- Not a general-purpose SharePoint client — scoped to the configured lists.

## 4. What changed since the request was created
- **Shifted from:** "add a UI feature that shows record availability" → **to:** "choose and validate the execution context that makes a session-authenticated read possible" (see §1 reframe).
- **What that buys us:** we avoid building a feature into a delivery context (local file) where it structurally cannot work, and we align the refactor's module seam with the delivery model.
- **What it still needs to prove:** F1–F4 empirically.

## 5. Why it exists
- **Origin traced to:** the tool was only ever a **URL string builder**. `urlForSite`/`buildUrl`/`combinedUrlForSite` (lines 527–545) concatenate `TENANT` + site + list + view + `?FilterField1=Title&FilterValue1=<value>`. There is **no `fetch`/XHR anywhere** in the file — so it structurally cannot know if a record exists. The monolith is a natural end-state for a hand-edited copy-paste utility (its own comments, lines 443–471, tell you to hand-edit the `SITES` array), but it becomes a liability the moment a data layer with async, error states, and parsing is added.
- **Evidence (primary-source pointers):** `SharePoint Lookup.html` lines 451 (`const TENANT`), 452–470 (`SITES`), 473 (`FILTER_FIELD = "Title"`), 527–545 (URL builders), full-file grep = zero network calls.
- **Contract alignment (software lens):** the authority for "does record X exist in list Y" is SharePoint itself; the authoritative read is `_api/web/lists/getbytitle('<list>')/items?$filter=<field> eq '<value>'`. **Drift risk:** the tool filters on `Title` (`FILTER_FIELD`), but if the record number is not the internal `Title` field, both the existing deep-links *and* the new availability query target the wrong field. → F3.
- **Detection gap (software lens):** there are **no tests at all** (single HTML file, no harness, not a git repo). Nothing could have caught a URL-format regression. The refactor should introduce URL-builder unit tests so AC1's byte-identical guarantee is enforceable — this is the red→green anchor.
- **Class re-check:** held — refactor = maintainability, feature = execution-context-gated capability. No flip.

## 6. Alternatives considered
| Alternative | Rejected because |
|-------------|------------------|
| MSAL / OAuth + Microsoft Graph | Explicit user constraint — no new auth method. Graph needs a bearer token, not a session cookie. |
| Local file + script `fetch` to `_api` | Cross-origin `fetch` to `_api` is CORS-blocked (no permissive `Access-Control-Allow-Origin` for arbitrary origins); can't read/parse the response in-tool. |
| Local file + "open the `_api` URL in a tab" | Works (navigation), but shows raw XML/JSON in a tab — cannot parse values back into the UI. Degraded floor only. |
| Server / proxy backend that holds the session | Adds infra + its own auth story; contradicts "down and dirty," no backend wanted. |
| SPFx web part (same-origin) | Same-origin so it works, but a heavier build/deploy pipeline than an extension; kept as the fallback if the extension path has trouble. |

## 7. Solution & stress-test
- **Proposed solution:** (a) **Refactor** into `index.html` + `styles.css` + JS modules with a clear seam — `config.js` (TENANT/SITES/FILTER_FIELD), `url-builder.js` (existing pure builders, unchanged output), `sharepoint.js` (**NEW** data layer: authenticated `_api` reads + parse), `app.js`/`ui.js` (rendering + wiring). (b) **Feature:** `sharepoint.js` issues `GET _api/web/lists/getbytitle('<list>')/items?$filter=<field> eq '<value>'&$select=Id&$top=1` with `Accept: application/json;odata=nometadata` and `credentials:"include"`; UI shows a per-list availability badge. (c) **Delivery:** ship as an MV3 extension (primary) or SharePoint-hosted page (fallback), decided after the spike.
- **Solves the confirmed class?** Yes — modular structure for maintainability; a valid execution context for the capability.
- **Scale:** the OJB lists are known (prior coverage, `docs/power-platform-aws-investigation/`) to hit the **5,000-item list-view threshold** and a **~300 calls / 60s** connection limit. Bulk availability that fires one query per title will throttle and can hit delegation limits. The data layer must **batch** (a single `$filter` with `Title eq 'a' or Title eq 'b' ...`, or a small concurrency cap) and degrade visibly at the threshold. → D5, and a future-development concern.
- **Generalization:** keep `sharepoint.js` narrow (these lists, existence/availability read) — a general SharePoint SDK would be overreach.
- **Fit:** an extension fits the user's existing toolkit (OtterCopy is MV3, loaded unpacked, no build step). A SharePoint page fits the tenant but changes how the tool is opened.
- **Adjacent issues:** the `Title`-field assumption (F3) affects the *existing* links too — cheap to confirm in the same spike; fix now if wrong.
- **Sufficiency:** covers both stated pains (maintainability + blind links). Does not, by itself, decide "availability = existence vs status" (D1) — that shapes how much of the pain is covered.
- **Feedback speed:** fast — the spike gives a yes/no in minutes. The only slow-feedback risk is tenant admin constraints (custom-script/hosting permissions for the SP-page option). → F5.
- **Happy-path story (30s):** the logged-in ops user opens the extension popup, pastes `633338`, and next to the OJB row a green "1 found" badge appears while OJB-Archive shows "not here" — they click straight to the real record instead of gambling on an empty filtered view. Without the extension/host-permission context, none of the badges can load.

## 8. Assumptions ledger
- **Claim:** The tool makes zero network calls today; it is purely a URL builder.
  - **Status:** confirmed — **Confirm/revise by:** full-file read + grep for `fetch`/`XMLHttpRequest` = none.
- **Claim:** A script `fetch` to `https://planetdepos.sharepoint.com/.../_api/...` from a non-SharePoint origin (a `file://` page) is CORS-blocked from reading the response, even with a valid session.
  - **Status:** confirmed directionally (established browser-security behavior; not yet observed for this tenant) — **Confirm/revise by:** F4 spike — attempt the fetch from a `file://` page and observe the console CORS error + unreadable response.
- **Claim (F1):** A same-origin page on `planetdepos.sharepoint.com` can read `_api` with the session cookie.
  - **Status:** open — **Confirm/revise by:** spike from a SharePoint-hosted context (or CDP-attached page on that origin).
- **Claim (F2):** An MV3 extension with `host_permissions` for the SharePoint domain can `fetch` `_api` with `credentials:"include"` and read the response (session cookie attached, page CORS bypassed).
  - **Status:** open — **Confirm/revise by:** load an unpacked test extension, fetch a known Title, observe parseable JSON. (OtterCopy proves host-permission cross-origin fetch works, but with token auth, not cookies — the cookie path is net-new.)
- **Claim (F3):** The record number the user types is the internal `Title` field of these lists (what the existing links filter on).
  - **Status:** open — **Confirm/revise by:** spike — `_api/web/lists/getbytitle('Operations Job Boards')/fields?$filter=...` or query `items?$filter=Title eq '<known>'&$top=1` for a Title known to exist; 0 results for a known-existing record ⇒ wrong field.
- **Claim:** The OJB lists hit a 5,000-item list-view threshold and ~300 calls/60s.
  - **Status:** confirmed directionally (prior coverage, `docs/power-platform-aws-investigation/`) — **Confirm/revise by:** applies to `$filter` delegation; verify the availability query stays indexed/`$top`-bounded.

## 9. Validation plan
**Happy path**
- Logged-in user → query a known-existing Title in OJB → `_api` returns 1 item → badge "found".
- Refactor: the same inputs produce **byte-identical** URLs to the current tool (single + combined + all-lists).

**Negative paths**
- Unknown Title → `_api` returns 0 items → "not found" (must not error).
- Expired/absent session → 401/403 → visible "sign-in expired, open SharePoint and retry", not a silent blank.
- Cross-origin/wrong-context fetch (`file://`) → blocked → the tool must not hang; it degrades to open-tab mode with a visible note. (Confirms F4.)
- Throttle (HTTP 429) or 5,000-item threshold → visible warning; bulk batches instead of N single calls. (Ties to D5.)
- Wrong filter field → 0 results for a Title known to exist → surfaces F3 as a visible "check field mapping" rather than a false "not found".

## 10. Decisions, recommendation & open variables
- **Decisions (settled):** no new auth method (AC4); read-only (non-goal); refactor introduces a data-layer seam; extension is the *primary candidate* pending the spike.
- **Recommendation (in order):** (1) run the feasibility spike (F1–F4) against a live authenticated browser; (2) decide D2 delivery model from the result; (3) do the refactor with the data-layer seam and URL-builder regression tests; (4) build the availability read + UI into the chosen context; (5) batch/degrade for the 5k/300-per-60s limits.
- **Sequencing & gates:** Do **not** start the feature build (step 4) until the spike proves a session-authenticated read is possible from the chosen context (AC2/AC5). The refactor (step 3) may proceed independently of the spike since it does not depend on the API result.

### Open variables to collect (true decisions — for Phase 3 grill-me)
- [ ] **D1** — meaning of "availability": existence/count vs a status-field value (and which field). — owner: user
- [ ] **D2** — final delivery model (extension vs SharePoint-hosted page vs degraded local), informed by the spike. — owner: user (with spike evidence)
- [ ] **D3** — product name: keep "SharePoint Shareplane", rename, and rename the file (currently "SharePoint Lookup.html"). — owner: user
- [ ] **D4** — availability UX: badge style; check automatically as you type/paste vs on-demand button; per-list vs first-hit. — owner: user
- [ ] **D5** — bulk behavior under limits: batch size, max titles per check, behavior at the 5k/429 boundary. — owner: user (informed by scale evidence)

*Fact-vs-decision note:* F1–F4 are **facts to discover** and are parked in §8, resolved by the spike — not brought to the user as decisions. They cannot be resolved by reading the current code (the tool makes no API calls and carries no list schema), so the evidence that proves "not answerable as-is" is: zero network code in the file + no schema/field metadata anywhere in the repo. D1–D5 are genuine decisions.

---

## 11. Plan — Next steps

### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Run feasibility spike (F1–F4) | agent + user (authenticated browser) | A console/log capture shows a session-cookie `_api` `$filter` read returning parseable JSON (or the exact block/error), from each candidate context |
| Decide D2 delivery model | user | One model chosen, recorded in the locked-decision ledger with the spike evidence cited |
| Refactor to modules + data-layer seam | agent | HTML/CSS/JS split; URL-builder unit test proves byte-identical URLs for the current inputs |
| Build availability read + UI | agent | For a known Title, the chosen context shows a correct per-list badge; negative paths degrade visibly |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)
- [ ] Feasibility spike executed (F1–F4) — **gates the feature build**

#### Project Spec
- [ ] Resolve D1–D5 via grill-me (Phase 3)
- [ ] Create spec + locked-decision ledger

#### Development
- [ ] Refactor (data-layer seam) — may start before the spike
- [ ] Feature build — gated on spike

#### Testing & Validation
- [ ] URL-builder byte-identical regression test
- [ ] Availability happy/negative paths

---

## 12. Definition of done (investigation gate)
- [x] Class derived from instances, re-confirmed against root cause; "reframed?" answered (yes, for the feature)
- [x] Problem Check pass recorded, quote-grounded
- [x] Problem in one plain sentence
- [x] Named blocked instance (Jaimie, OJB/VUL/Archive links)
- [x] Trigger it bites next (feature build forces the refactor)
- [x] Wedge + why reusable (one authenticated read)
- [x] Acceptance criteria + non-goals locked before solution
- [x] Alternatives recorded with rejection reasons
- [x] 30-second happy-path story
- [x] Metric + feedback speed (spike = minutes)
- [x] Verdict + disposition (proceed with conditions)
- [x] Open questions reconciled — facts (F1–F4) in §8 (spike), only decisions (D1–D5) in §10
- [x] Tracked action with falsifiable done-when (handoff table)

---

## 13. Post-Investigation Addendum — Feasibility spike results (2026-07-23)

> Appended per the orchestrate "reopening a done report" rule — earlier sections and the verdict are unchanged; this records the empirical spike evidence that the report was gated on.

Ran `scratchpad/spike-sharepoint-api.mjs` (Playwright over CDP `http://localhost:9222`, attached to a Chrome the user launched with `--remote-debugging-port=9222 --user-data-dir=C:\temp\shareplane-cdp-profile` and logged into `planetdepos.sharepoint.com`). Read-only GETs against `_api/web/lists/getbytitle('...')/items`.

**Raw results (Stage 1):**
- **F1 (same-origin read) — CONFIRMED.** Unfiltered `$top=3&$select=Id,Title` on OJB → `ok:true, status:200, count:3`, real values `Title: "000001","000004","000007"`. The existing browser 365 session cookie reads `_api` with no new auth.
- **F3 (filter field) — CONFIRMED.** `$filter=Title eq '000001'` → `count:1`, exact match. `Title` is the identifying field (consistent with the existing deep-links). **New finding:** record numbers are **zero-padded 6-char strings** (`"000001"`); `$filter Title eq` is an *exact* match, so an un-padded input (`1`) will not match. → feeds D1/D4 (input normalization / padding).
- **NP-1 (missing value) — CONFIRMED.** Bogus Title → `count:0`, `ok:true`, no error. The graceful not-found path works.
- **F4 (file:// origin) — CONFIRMED.** The same fetch from a `file://` page → `error:"Failed to fetch"` (CORS-blocked). A local double-click file cannot read/parse `_api`.
- **F2 (extension cookie-fetch) — NOT YET TESTED.** Requires a loaded MV3 test extension (Stage 2).
- Incidental: responses carry `odata.nextLink` paging (irrelevant for `$top=1` existence checks); items expose both `Id` and `ID`.

**Raw results (Stage 1b — cross-list, real numbers via `scratchpad/spike-crosslist.mjs`):**
- OJB `Title='621571'` → count 1 (found, as expected). OJB `Title='627259'` → count 0 (not there, as expected).
- Archive `Title='627259'` → count 5 (found — **five copies**; `$top=5` so possibly more). Archive `Title='621571'` → count 2 (**found — the user expected it NOT in Archive; it is there twice**).
- **Finding → D1:** availability is **not binary**. Records duplicate within a list and appear across lists; a yes/no check would hide this. The feature should report a **per-list count** (and a real count needs `$count`/`$inlinecount` or a higher `$top`, since `$top=5` truncates). The cross-list surprise (621571 also in Archive) is a live demonstration of the tool's value.

**Impact on decisions:**
- **D2 delivery model:** same-origin (SharePoint-hosted) is empirically viable; local-file is empirically dead for in-tool parsing. The extension (primary candidate) is still gated on F2.
- **Assumptions ledger:** F1 → confirmed; F3 → confirmed (+ format finding); file:// CORS block → confirmed; F2 → still open.
