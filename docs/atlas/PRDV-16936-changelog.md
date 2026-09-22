# PRDV-16936 — Atlas Prototype: Case Details Page

## Ticket

- **ClickUp:** [PRDV-16936](https://app.clickup.com/t/43227262/PRDV-16936)
- **Repo:** `proteus-front-end` (product-authoring lane; ships the Atlas UI in React/shadcn)
- **Branch:** `prototype-main`
- **PR:** none — the ticket scopes this branch as a maintained prototyping resource, retired once all pages are built properly in Proteus `main`
- **Reference (read-only):** `atlas-front-end` (visual/behavioral source of truth), `callisto-back-end` (response shapes only)
- **Artifacts:** [PRDV-16936/](PRDV-16936/) — original ticket, requirements/readiness, transcript, and the implementation/review artifact `PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md`

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

> **Original Request**
> As a Product Manager, I want a realistic, clickable prototype of the existing **Atlas Case Details page** using fake data, so that I can quickly create and iterate designs for new and upcoming features for stakeholders using components that will be consistent with our upcoming shadcn/react refactor work.
>
> Dev Notes:
>
> - Utilize React & Shadcn
> - Utilize "json mock server" data structures as "backend" to enable prototyping
> - Create a branch in proteus called "prototype-main" for this work. This branch will be maintained with prototyping resources and updated with pages built out properly in proteus from main branch until all pages have been built out correctly, then this branch will be retired
>
> **Acceptance Criteria**
>
> - Shaye is able to load the prototype into claude code to make structural and design changes as needed
> - Prototype includes the following
> - All existing Case Info fields
> - Case Name
> - Case ID
> - Case Number
> - Restricted Access panel and info
> - Jobs List / Case Files tabs
> - Jobs List
> - All current columns
> - Case Files
> - All current case categories
> - All current actions

---

## Context

- Speed over polish is explicit in the ticket and the sprint transcript — this is a vibe-coded facade for product design, not a Callisto integration. Automated tests are intentionally light; the repo has no test harness (`test:unit:ci` is a stub, zero spec files).
- Atlas is the **visual source of truth**. Departures from it are allowed only where a Proteus shell constraint, semantic token, accessibility need, or missing shadcn behavior forces one — and must be recorded.
- The prototype runs a permissive U.S. demo persona. No real permissions, entitlement, or authorization is modeled.
- Follow-on tickets from the same transcript: Job Detail page and Proceeding Detail page, same prototype lane.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-17 | [PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md](PRDV-16936/PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md) | `implemented` | Five-packet multi-agent build (A data foundation → B header/restrictions, C Jobs tab, D Case Files tab → E integration), each on its own local branch with a coordinator review/merge gate. |
| 2026-09-17 | AC-by-AC parity review + fix pass (this session) | `implemented` | Compare the shipped page against the ticket's seven ACs with Atlas source and a live Chromium run; fix every gap found except the ones explicitly deferred. |

---

## Session log

### 2026-09-17T21:55:00Z — proteus-front-end — AC parity review and fix pass

- **Problem:** Packets A–E shipped the prototype, but no pass had checked the result against the ticket's own acceptance criteria. The E-record's parity claim was a source read, and the one browser pass that existed predated the final `0db52daf` revert.
- **Requirement:** Every AC either demonstrably satisfied on the running page, or the gap named with file/line evidence and a decision recorded.
- **Method:** Read the Atlas Vue/SCSS source and i18n as source of truth, then drove the running prototype with Playwright/Chromium (browsers were cached locally; the `playwright` package was installed ad hoc in the scratchpad, never added to the repo). Four probe passes at 1440×900 and 390×844.

**Review result — three ACs clean, four with defects:**

| AC | Verdict |
| --- | --- |
| AC1 handoff (Shaye can load it in Claude Code) | Pass — gate green, `origin/prototype-main` exists at the local tip, mocks on by default |
| AC2 Case Info fields | Pass — `CASE` / name / `Case ID:` / `Case number:`, label-for-label with `CaseHeader.vue` |
| AC3 Restricted Access panel | 2 defects — badge dropped the level; no visibility-off icon |
| AC4 Jobs / Case Files tabs | 1 defect — zero-count badges never muted, and the empty-category variant was *inverted* |
| AC5 Jobs List columns | 3 defects — no sort affordance; date format; restricted cases rendered a dead tab |
| AC6 Case Files categories | Pass — all seven, exact order, counts, empty category retained |
| AC7 Case Files actions | 5 defects — **download was a silent no-op**; raw Type value; no timestamp; rename could destroy the extension; no sort affordance |

**Fixes shipped this session** (five parallel Sonnet subagents across disjoint file sets, plus coordinator corrections):

- **Download no longer silently fails.** `window.open()` on a `data:` URI is blocked by Chrome as a top-level navigation — both "Download all" and "Download selected" did nothing, with no error. Replaced with a programmatic `<a download>` click (verified: fires a real download). Mock route unchanged.
- **Type column** renders Atlas-style labels (`PDF Document`, `Microsoft Word Document`) via a new page-local `getFileTypeLabel` — a ~14-entry subset of Atlas's ~150-entry map. Upload now stores a bare extension off `file.name` instead of the File API MIME type, so uploaded and seeded rows agree (previously `APPLICATION/PDF` beside `PDF`).
- **Last modified** shows date **and** time (`DATETIME_FORMAT_LONG`).
- **Rename** pre-fills the stem only and renders the extension as static text, matching Atlas's `getFileNameWithoutExtension` behavior — a rename can no longer drop `.pdf`.
- **Restriction badge** reads the level-specific label (`Restricted: U.S. Only` at level 2) from a new `CASE_RESTRICTION_ACCESS_LABELS` map, with an `EyeOff` icon.
- **Zero-count badges** use `outline`; populated use `default`.
- **Restricted cases show live proceedings again.** Per Atlas's own copy, level 1 keeps case/job information visible and gates only *file contents*; level 2 is the same but U.S.-only. The fixture was blanking every proceeding on any restricted case, so cases 2/3/7 demoed twelve rows of "Restricted" with zero links while their Case Files tab stayed fully interactive. Substitution is now scoped to one named demo case (7) so the placeholder state stays demoable.
- **Job date** uses Atlas's `MM / dd / yyyy` format. The deliberate divergence on null `startTime` is preserved (Atlas renders a dangling `@`; we omit the segment).
- **Sortable columns** on Job number and File name only — matching Atlas's `sortable: true` flags exactly — via a new page-local `SortableTableHead` with `aria-sort`. Client-side, display-order only; selection and select-all are unaffected.
- **Selected-actions bar** matches Atlas's `fab.*` copy (`Total selected`, `Download {n} selected`, `Delete all selected`, `Select a single file to rename`, `Deselect all (Esc)`) and clears the selection on Escape.
- **Narrow-viewport overflow closed.** Diagnosed by walking the DOM for elements passing the viewport edge whose parent does not — the cause was the category header row: `justify-between` with a 194px action group at `min-width: auto` that could not shrink. The row now wraps and the title group can shrink. Case Files measures **571 at 390px, identical to the `/cases` baseline** (was 591). No magic constants.

**Coordinator corrections to subagent output** (each invisible to the agent, which was instructed not to run gates):

- Header packet did not compile — `Object.fromEntries` returns a string-indexed type, not `Record<CaseRestrictionLevel, string>` (TS2739). Fixed by inverting the dependency: the labels map is now the literal source of truth (mirroring Atlas's `auth/types.ts` shape) and the options array reads its labels from it. No cast, no duplicated strings.
- The timestamp fix exposed a fixture defect: `TODAY` is `startOfDay()`, so every seeded file rendered "at 12:00 AM". Added a deterministic business-hours offset. **Side effect:** the extra `int()` calls advance the shared PRNG, so downstream category counts shifted — still fully deterministic, just different demo data.
- A stale doc comment on `getCaseJobsByCaseId` still claimed it applied the restriction level to proceedings.
- `npm run lint:fix` for import-order/spacing across three files.

- **Deliberately not fixed:**
  - **Escape inside the Rename drawer closes the drawer *and* clears the selection** (verified: `drawerStillOpen: false, selectionSurvived: false`). Atlas attaches the same unguarded `document` listener with no propagation check, so it is structurally exposed the same way — but Atlas could not be run to confirm its actual behavior, so parity is **not** claimed. A guard would be a compensating layer; left for a product call.
  - Size formatting differs (`178.1 KB` vs Atlas's `178.13 kb`) — judged more readable, recorded as a deliberate departure.
  - Case Files tab is always enabled (permissive persona — a pre-existing recorded decision).
- **Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | — | `proteus-front-end` | not run | **Blocked by scope, not by tooling:** this session was a review + fix pass, not a commit. `npm audit --audit-level=high` is a pre-commit gate per `git-commit-workflow`; it must be run before the commit that lands this work. Residual risk: unreviewed dependency advisories. No dependency or lockfile changed this session. |
| lint | `npm run lint` (after `npm run lint:fix`) | `proteus-front-end` (`eslint "src/**/*.{ts,tsx}"`) | pass | — |
| type-check | `npm run type-check` (`tsc -b`) | `proteus-front-end` | pass | — |
| build | `npm run build` | `proteus-front-end` | pass | pre-existing >500 kB chunk-size warning only, unrelated |
| browser | Playwright/Chromium, 1440×900 + 390×844 | `/cases`, `/cases/1`, `/cases/2`, `/cases/7`, both tabs | pass | **0** console errors, **0** page errors across every flow |

- **Tests added/updated:** none — **exception applies.** The repo has no runnable harness (`test:unit:ci` is a stub; zero `*.spec.*`/`*.test.*` files under `src/`), and the ticket explicitly scopes automated tests as intentionally light for this prototype. Behavior was instead verified end-to-end in a real browser (table above). Residual risk: no regression net for the sort comparators, `getFileTypeLabel`, or the rename stem/extension split. Smallest follow-up that would unlock coverage: wire a Vitest config for `src/pages/CaseDetail/**` and start with those three pure functions.
- **Commits:** none — working tree left uncommitted at the user's request pending their own manual test pass.

### 2026-09-17T17:04:00Z — proteus-front-end — Packets A–E build and review

- **Summary:** Full prototype built and reviewed through the five-packet model in [PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md](PRDV-16936/PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md), which holds the per-packet evidence, findings (F1–F3, B1, D1, E1–E5), and merge verdicts. Not duplicated here — that artifact is the authoritative build record.
- **Landed:** `prototype-main` at `0db52daf` — typed case/jobs/case-files API + mock foundation, Atlas-parity header with restriction drawer, Jobs tab, Case Files tab with simulated upload/preview/download/rename/delete, and the tabbed integration replacing the old proceedings body.

---

## Attempt history

### Attempt 1 — blanket restriction on case jobs (superseded 2026-09-17)

Packet A's fixture substituted the `Restricted` placeholder for every proceeding whenever `restrictionLevel > 0`. It survived packet review because it looks correct in isolation and matches the artifact's "a restricted placeholder is text, not a link" evidence. It is wrong at the page level: Atlas resolves restriction against the *viewing user's* access, and the prototype's persona has access. Result was three cases (2, 3, 7) with a fully dead Jobs tab. Replaced with a single named demo case.

---

## Key technical learnings

- **`window.open()` cannot trigger a `data:` URI.** Chrome blocks it as top-level navigation — silently, with no console error. A programmatic `<a download>` click is not a navigation and works. Any future simulated download in this lane should use the anchor.
- **A green gate does not imply a working page.** E1–E4 in the prior session, and all ten defects found in this one, were invisible to type-check, lint, build, and source reading. Browser observation is what found them.
- **`secondary` is brighter than `default` in this theme** (`rgb(42,31,255)` vs `rgb(6,36,126)`), which is the opposite of the usual assumption — it is why the empty-category badge was the loudest element on the page. Use `outline` for a muted badge.
- **Subagents split by file ownership, not by finding.** Splitting by finding put two agents in `CaseFilesTable.tsx` and two in `CaseHeader.tsx`; the earlier Packet B/D collision in a shared checkout is the same failure. Disjoint file sets ran five agents with zero collisions.
- **Agents told not to run gates cannot catch what gates catch.** Two of five hand-backs needed correction (one did not compile). Parallel agents plus one central verification pass is the shape that works — the verification is not optional overhead.

---

## Current state (as of 2026-09-17)

- `prototype-main` is at `0db52daf` on both local and `origin`, **plus an uncommitted working tree** carrying this session's parity fixes across 12 files.
- All seven ticket ACs are satisfied on the running page. No open defect from the parity review remains, except the two recorded deliberate departures (Escape-clears-selection inside a drawer; size formatting).
- Nothing is committed or pushed from this session. Next step is the user's manual test pass, then audit → lint → tests → commit per `git-commit-workflow`.
- **Two stale records corrected in the build artifact this session:** its Packet E record still read "Merge verdict: READY TO MERGE, HELD" / "Merged SHA: Not merged" and "no remote operation occurred" — Packet E is in fact merged into `prototype-main`, and the branch is pushed to `origin`.

---

## New code introduced

Added this session (all under `proteus-front-end`):

| Path | What |
| ---- | ---- |
| `src/pages/CaseDetail/components/SortableTableHead.tsx` | Page-local sortable header: `aria-sort`, lucide chevrons, optional `children` slot so the select-all checkbox renders beside the sort button rather than nested inside it (invalid HTML) |
| `src/pages/CaseDetail/hooks/caseFileFormatting.ts` | `getFileExtension` + `getFileTypeLabel` added beside the existing `formatFileSize` |
| `src/lib/time.ts` | `DATE_FORMAT_ATLAS` (`MM / dd / yyyy`) |
| `src/pages/CaseDetail/constants.ts` | `CASE_RESTRICTION_ACCESS_LABELS`, now the source of truth the level options read their labels from |
