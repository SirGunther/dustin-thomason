> **UNFILLED SHELL — staged at Phase 2, body written at Phase 5.** Headings only, deliberately. Scope can still move through Phases 3 and 4, and the Description / Test Evidence / Commit sections are filled *after* the change is implemented and verified, from the testing-implementation artifact. Do not fill this early.

# PR title

_(Phase 5. Format per `pull-request-workflow.md`; commit subject convention is `PRDV-16403: <five to seven descriptive words>`.)_

### Clickup

_(Phase 5 — link as `[Clickup - PRDV-16403 - Display Firm, Case, Contact & Case Remarks in Access Manager](https://app.clickup.com/t/43227262/PRDV-16403)`.)_

### Description

**Must state, because a reviewer cannot infer it:**

- Case warnings and Case remarks were **populated by hand in the database** to verify them, because the replication mapping that normally supplies them has not shipped. Both worked once populated.
- Sanitisation of the remarks html was **verified manually in a browser, not by the test suite** — DOMPurify does not sanitize correctly under the test environment, so the automated specs only prove that raw html is always routed through the sanitizer.

_(Phase 5. Source: `PRDV-16403-why-these-changes.md` — the categorized change breakdown with Before / After / Why per change. Frame Problem → Requirement → Solution. Change rationale belongs here, never as a source comment.)_

### Commit

_(Phase 5 — one fenced block containing only the forty-character hash from `git rev-parse HEAD`. Two repos are in play, so expect one hash per repo, each labelled.)_

### Test Evidence

_(Phase 5. Paste the assembled block from `testing/PRDV-16403-testing-implementation.md` — scenario-first, each scenario with why it matters and whether it held. Gate results go in a table with exact command, scope and result. **If manual verification was not possible, say so plainly here** — see concern C4 / decision D7; do not leave it implied by silence.)_

### Checklist

_(Phase 5 — per the repo template.)_
