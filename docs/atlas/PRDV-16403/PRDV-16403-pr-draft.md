> **UNFILLED SHELL — staged at Phase 2, body written at Phase 5.** Headings only, deliberately. Scope can still move through Phases 3 and 4, and the Description / Test Evidence / Commit sections are filled *after* the change is implemented and verified, from the testing-implementation artifact. Do not fill this early.

# PR title

_(Phase 5. Format per `pull-request-workflow.md`; commit subject convention is `PRDV-16403: <five to seven descriptive words>`.)_

### Clickup

_(Phase 5 — link as `[Clickup - PRDV-16403 - Display Firm, Case, Contact & Case Remarks in Access Manager](https://app.clickup.com/t/43227262/PRDV-16403)`.)_

### Description

**Must state, because a reviewer cannot infer it:**

- **What the two case sections do right now.** `contacts.warning` and `firms.warning` are live replicated columns, so **Contact warnings and Firm warnings show real data today**. PRDV-16391 added `cases.warning` / `cases.remarks` / `cases.remarks_html` and this endpoint reads them, but **PRDV-16392 (the DMS CDC mapping) has not shipped, so nothing writes to those columns** - they are `null` in every environment. **Case warnings therefore reads "None" and Case remarks reads "No remarks info" until 16392 lands**, which states "nothing recorded" where the truth is "not yet replicated". This is known and accepted for this window. **No change to Atlas or Callisto is needed when 16392 ships** - both sections populate on their own the moment data arrives.
- Case warnings and Case remarks were **populated by hand in the database** to verify them, for the same reason. Both worked once populated.
- Sanitisation of the remarks html was **verified manually in a browser, not by the test suite** - DOMPurify does not sanitize correctly under the test environment, so the automated specs only prove that raw html is always routed through the sanitizer.
- **Empty warnings read "None"**, taken from Figma, rather than the ClickUp criterion's "No warning info". Empty case remarks read "No remarks info" as specified. Deliberate; Figma governs wording.
- **A retry defect was found and fixed while writing the failure-path coverage.** The warnings query took vue-query's default `retry: 3`, which compounds with the three transient-network retries `globalApi/apiClient.ts` already performs - a refused connection became 16 requests and roughly 35s of spinner before the panel could say it failed. Now `retry: 1`, matching the other Callisto read queries.
- **The failure path is covered end to end**, by `AccessManagerWarningsFailurePath.spec.ts`, which drives a rejected request through the real query client, composable, panel and locale file. A **browser** check against a genuinely refused connection has not been performed.

_(Phase 5. Source: `PRDV-16403-why-these-changes.md` — the categorized change breakdown with Before / After / Why per change. Frame Problem → Requirement → Solution. Change rationale belongs here, never as a source comment.)_

### Commit

_(Phase 5 — one fenced block containing only the forty-character hash from `git rev-parse HEAD`. Two repos are in play, so expect one hash per repo, each labelled.)_

### Test Evidence

_(Phase 5. Paste the assembled block from `testing/PRDV-16403-testing-implementation.md` — scenario-first, each scenario with why it matters and whether it held. Gate results go in a table with exact command, scope and result. **If manual verification was not possible, say so plainly here** — see concern C4 / decision D7; do not leave it implied by silence.)_

### Checklist

_(Phase 5 — per the repo template.)_
