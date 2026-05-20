# PRDV-12264 — File names overlap other columns

## Ticket

- **ClickUp:** [PRDV-12264](https://app.clickup.com/t/43227262/PRDV-12264)
- **Repo:** `atlas-front-end`
- **Branch:** `PRDV-12264`
- **PR:** [#497](https://github.com/planetdepos/atlas-front-end/pull/497)

---

## Requirements (from ticket)

- **Actual result:** Really long file names exceed the screen or clip into other columns.
- **Expected result:** File name is truncated into one line once it hits ~50% of screen width with a tooltip displaying the full file name on hover.
- **Scope:** Submissions tab, Client Deliverables tab, Case Files.
- **Dev note:** Rely on `text-overflow: ellipsis`. This is essentially 3 data grids.

---

## Plans

| Added | Plan | Status | One-line approach |
| ----- | ---- | ------ | ----------------- |
| 2026-05-20 | _(read-only)_ `larry-adams/systems/neptune/maintenance/truncate-long-filenames/PRDV-12264-truncate-long-filenames.md` | `active` | Coworker spec — link only; changelog lives in dustin-thomason |
| 2026-05-20 | In-session: `table-layout: fixed` on all parent tables | `superseded` | Session 2 — reverted session 3; see Attempt history |
| 2026-05-20 | In-session: `max-width: 50vw` on inner `.fileLink` spans | `superseded` | Session 3 — replaced by container-query approach in session 4 |
| 2026-05-20 | In-session: container-query `max-width: 40cqw` on `.fileLink` spans | `implemented` | Session 4 — `container-type: inline-size` on table wrappers, `40cqw` on text spans |

---

## Session log

_Newest first. Older debugging detail lives in **Attempt history** below._

### 2026-05-20 (session 8) — atlas-front-end

- **Summary:** Addressed second round of reviewer feedback (p-lana, derrickdso). (1) Replaced `:ref` callback (`setTextRef`) with direct `:ref="textRef"` binding in both `CaseFileNameCell.vue` and `ProceedingFileTableDataRow.vue` — Vue accepts `Ref<HTMLElement>` directly, no callback needed. Removed `ComponentPublicInstance` import. (2) Collapsed duplicate `<span>` blocks in both components into a single `<span>` driven by computed properties (`isClickable`/`spanClass`/`tooltipText`/`handleClick` in CaseFileNameCell; `isFileClickable`/`fileLinkClass`/`fileTooltipText`/`handleFileClick` in ProceedingFileTableDataRow). Each component now has one span for the filename instead of two/three near-identical blocks.
- **Files:**
  - `CaseFileNameCell.vue` — single span with computed class/tooltip/click; direct ref binding; removed `setTextRef` method and `ComponentPublicInstance` import
  - `ProceedingFileTableDataRow.vue` — single file link span with computed class/tooltip/click; direct ref binding; removed callback
- **Key insight:** Vue's template `:ref` accepts a `Ref` directly and auto-assigns `.value`. The callback pattern was unnecessary indirection. Collapsing conditional spans into computed properties eliminates logic duplication while preserving identical runtime behavior.

### 2026-05-20 (session 7) — atlas-front-end

- **Summary:** Reverted global ToolTip change (session 6 mistake) and replaced with targeted tooltip wrapping. Added `.tooltipContent` class to `CaseFileNameCell.module.scss` and `ProceedingFileTableDataRow.module.scss` with `max-width: 50vw` + word-wrap. Applied only to filename tooltip slots via `<span>` wrappers inside `<ToolTip>`. Global `ToolTip.vue` restored to exact `main` state; `ToolTip.module.scss` deleted.
- **Files:**
  - `globalComponents/ToolTip.vue` — reverted to `main`
  - `globalComponents/ToolTip.module.scss` — deleted
  - `CaseFileNameCell.module.scss` — added `.tooltipContent` class
  - `CaseFileNameCell.vue` — wrapped filename text in tooltip slots with styled `<span>`
  - `ProceedingFileTableDataRow.module.scss` — added `.tooltipContent` class
  - `ProceedingFileTableDataRow.vue` — wrapped filename text in tooltip slots with styled `<span>`
- **Key insight:** Tooltips are portaled to `<body>` by Quasar so `cqw` units won't work. `50vw` is correct for floating overlays. But changing the global `ToolTip.vue` affects every tooltip in the app — scope the fix to the filename slots only.

### 2026-05-20 (session 6) — atlas-front-end (REVERTED in session 7)

- **Summary:** Added word-wrap to global `ToolTip.vue` to fix long filename tooltips not wrapping at small screen sizes. **This was a mistake** — it modified a shared global component, affecting all tooltips app-wide. Reverted in session 7.
- **Files:**
  - `globalComponents/ToolTip.vue` — added SCSS module import and `:class` binding
  - `globalComponents/ToolTip.module.scss` — new file with `max-width: 50vw`, word-wrap
- **Lesson:** Do not modify global shared components for feature-specific needs. Scope changes to the consuming components.

### 2026-05-20 (session 5) — atlas-front-end

- **Summary:** Addressed PR review feedback. (1) Moved `.fileLink`/`.fileLinkDisabled` from `CaseFilesTable.module.scss` to new `CaseFileNameCell.module.scss` per reviewer request to co-locate styles with consuming component. (2) Extracted repeated `:ref` callback into reusable `setTextRef` method in `CaseFileNameCell.vue`. (3) Simplified `v-if`/`v-else-if`/`v-else` to two-branch `v-if`/`v-else` in `CaseFileNameCell.vue`. (4) Created `src/css/_truncation.scss` with generic `@mixin truncate-text($max-width: 40cqw)` — both SCSS modules now import the mixin instead of duplicating truncation rules. (5) Removed extraneous `flex: 1` and `min-width: 0` from `ProceedingFileTableDataRow.module.scss` that were inadvertently introduced (not present on `main`). (6) Removed `file-link-class` prop from `CaseFilesTable.vue` → `CaseFileNameCell.vue` interface.
- **Files:**
  - `CaseFileNameCell.module.scss` — new file; `.fileLink`/`.fileLinkDisabled` with `@include truncate-text` + `display: inline-block; vertical-align: middle`
  - `CaseFileNameCell.vue` — imports own SCSS module, `setTextRef` method, simplified conditionals, added `ComponentPublicInstance` type import
  - `CaseFilesTable.module.scss` — removed `.fileLink` (moved to child)
  - `CaseFilesTable.vue` — removed `:file-link-class` prop
  - `ProceedingFileTableDataRow.module.scss` — replaced standalone `overflow: hidden` with `@include truncate-text`; removed accidental `flex: 1`/`min-width: 0`
  - `src/css/_truncation.scss` — new shared mixin
- **Key insight:** `display: inline-block` + `vertical-align: middle` are required on `CaseFileNameCell` because it's a `<span>` inside a `<td>` — truncation CSS needs block-level context. `ProceedingFileTableDataRow` doesn't need these because its span is inside a flex container.

### 2026-05-20 (session 4) — atlas-front-end

- **Summary:** Replaced viewport-relative `max-width: 50vw` with container-query-relative `max-width: 40cqw`. Added `container-type: inline-size` to all three table wrapper classes so `cqw` units resolve to the table container width, not the browser viewport. `40cqw` visually places the filename truncation point at approximately 50% of the table's visible width (accounting for checkbox + padding offset).
- **Files:**
  - `SubmissionFilesTable.module.scss` — added `container-type: inline-size`
  - `ClientDeliverablesTable.module.scss` — added `container-type: inline-size`
  - `CaseFilesTable.module.scss` — added `container-type: inline-size`; changed `max-width: 50vw` → `40cqw` on `.fileLink`/`.fileLinkDisabled`
  - `ProceedingFileTableDataRow.module.scss` — changed `max-width: 50vw` → `40cqw` on `.fileLink`/`.fileLinkDisabled`
- **Key insight:** `50vw` measured from viewport edge, not content area — sidebar offset made it overshoot. Container queries (`cqw`) measure from the table wrapper, giving a stable reference point regardless of sidebar width or viewport size. `40cqw` ≈ visual 50% of table after accounting for left-side checkbox/padding.

### 2026-05-20 (session 3) — atlas-front-end

- **Summary:** Reverted `table-layout: fixed`, `min-width`, and `overflow: hidden` on `.fileName` from session 2 — those constrained the column but did not cap the text at 50% of the viewport. Replaced with `max-width: 50vw` on the inner `.fileLink` / `.fileLinkDisabled` text elements. This viewport-relative cap truncates filenames at exactly 50% of screen width under `table-layout: auto` (the `main` default), preserving all existing column sizing and horizontal scroll behavior.
- **Files:**
  - `SubmissionFilesTable.module.scss` — removed `table-layout: fixed`
  - `ClientDeliverablesTable.module.scss` — removed `table-layout: fixed`
  - `CaseFilesTable.module.scss` — removed `table-layout: fixed`, `overflow: hidden`, `min-width`; replaced `max-width: calc(100% - 60px)` with `max-width: 50vw` on `.fileLink`/`.fileLinkDisabled`
  - `ProceedingFileTableDataRow.module.scss` — removed `overflow: hidden` from `.fileName`, removed `min-width` from `.fileSize`/`.fileType`/`.actions`; added `max-width: 50vw` to `.fileLink`/`.fileLinkDisabled`
- **Key insight:** The constraint belongs on the inner text span (`max-width: 50vw`), not on the `<td>` or `table-layout`. Viewport units work under any `table-layout` mode and directly express the ticket requirement.

### 2026-05-20 (session 2) — atlas-front-end

- **Summary:** Applied `table-layout: fixed` to all three parent tables (SubmissionFilesTable, ClientDeliverablesTable, CaseFilesTable). Added `min-width` to non-filename columns in ProceedingFileTableDataRow and CaseFilesTable so they resist collapsing and trigger horizontal scroll at narrow viewports (matching `main` behavior). Added filename truncation + `useTextTruncation` tooltip to CaseFileNameCell. Added `.fileLinkDisabled` class to CaseFilesTable SCSS and passed as prop.
- **Files:**
  - `SubmissionFilesTable.module.scss` — added `table-layout: fixed`
  - `ClientDeliverablesTable.module.scss` — added `table-layout: fixed`
  - `CaseFilesTable.module.scss` — added `table-layout: fixed`, `overflow: hidden` on `.fileName`, truncation styles on `.fileLink`/`.fileLinkDisabled`, `min-width` on non-filename columns
  - `ProceedingFileTableDataRow.module.scss` — added `min-width` on `.fileSize`/`.fileType`/`.actions`
  - `CaseFileNameCell.vue` — integrated `useTextTruncation`, added `textRef` binding, conditional `<ToolTip>`, new `fileLinkDisabledClass` prop
  - `CaseFilesTable.vue` — passed `:file-link-disabled-class` prop to `CaseFileNameCell`
- **Notes:** All column class names and width percentages unchanged from `main`. `min-width: 120px` on Size/Type/LastModified, `min-width: 60px` on Actions.

### 2026-05-20 — atlas-front-end

- **Summary:** Narrowed scope to `ProceedingFileTableDataRow` + `useTextTruncation`; reverted Case Files / parent table SCSS to `main` pending follow-up.
- **Files:** `ProceedingFileTableDataRow.vue`, `ProceedingFileTableDataRow.module.scss`, `useTextTruncation.ts`, `useTextTruncation.spec.ts`
- **Notes:** Parent tables need `table-layout: fixed` when those tabs are updated.

---

## Root cause analysis

Quasar's global stylesheet applies `white-space: nowrap` to all `q-table` cells. Combined with `table-layout: auto` (the browser default), long single-word filenames force their column wider than any declared `width`, pushing Size/Type/Actions columns off-screen. This was a **pre-existing bug on `main`** — not introduced by any recent change.

The original column classes on `main` had `width` values (e.g. `.fileName { width: 40% }`, `.fileSize { width: 20% }`) but under `table-layout: auto` those are treated as **minimum-width hints**, not enforced maximums. When content exceeds them, the browser overrides.

---

## Attempt history

### Attempt 1 — CSS-only truncation on `.fileLink` (commit `3032b8cc`)

**What:** Added `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` to the inner `.fileLink` span inside the filename `<td>`.

**Result:** Did not prevent column expansion because `overflow: hidden` on an inline/flex child inside a `<td>` does not constrain the `<td>` itself when `table-layout: auto` is active. The `<td>` still grew to fit content.

### Attempt 2 — Non-PDF file truncation fix (commit `3d735c23`)

**What:** Realized `.fileLinkDisabled` (used for non-PDF files) had no truncation styles. Also, the class was conditionally applied only to PDFs — non-PDF files got no class at all.

**Result:** Fixed truncation for non-PDF files by always applying `styles.fileLinkDisabled` to the `v-else` span. However, the column expansion bug persisted because the root cause (`table-layout: auto`) was not addressed.

### Attempt 3 — `overflow: hidden` on `.fileName` `<td>` (commit `f98ad725`)

**What:** Added `overflow: hidden` directly to the `.fileName` `<td>` element.

**Result:** Insufficient. Under `table-layout: auto`, `overflow: hidden` on a `<td>` is ignored when the content's intrinsic width exceeds the declared width.

### Attempt 4 — `table-layout: fixed` with explicit `<th>` widths (commit `0d467891`)

**What:** Added `table-layout: fixed` to all three tables and set explicit percentage/pixel widths on all `<th>` elements via class bindings.

**Result:** Fixed the column expansion bug. Columns now respect their declared widths. However, the user reported extensibility concerns — hardcoded widths on all columns meant adding new columns would require recalculating all percentages.

### Attempt 5 — `width: 1px` on non-filename columns (commit `58267e38`)

**What:** Tried the `width: 1px` CSS trick on non-filename columns to let them shrink to content width, with filename taking the remaining space.

**Result:** Failed. The `width: 1px` trick only works with `table-layout: auto`. With `table-layout: fixed`, `1px` is taken literally and the columns collapsed to 1px. Everything shifted too far right.

### Attempt 6 — 50% cap with auto-distribute (commit `993fa652`)

**What:** Capped `.fileName` at `width: 50%` with `min-width: 150px`. Removed `.fileSize`, `.fileType`, `.lastModified` classes and their `<td>` `:class` bindings to let those columns auto-distribute.

**Result:** Visually close but violated team conventions — removing existing classes broke the team-agreed column structure. User feedback: "we need to honor the classes that were already pre-built by the other team members."

### Attempt 7 — Restore original classes + `table-layout: fixed` (commit `46ed61a1`)

**What:** Restored all original column classes and their width values exactly as `main`. Kept `table-layout: fixed` on tables. Added only `overflow: hidden` on `.fileName` and truncation styles (`text-overflow: ellipsis`, `white-space: nowrap`) on inner link elements.

**Result:** Original column structure preserved. Truncation works with ellipsis and conditional tooltip. However, user testing revealed "still some weirdness" — needs further refinement.

---

## Key technical learnings

1. **`table-layout: auto` vs `fixed`:** Under `auto`, `width` on `<td>`/`<th>` is a minimum hint. Under `fixed`, it's enforced. Switching to `fixed` is the only reliable way to prevent content from expanding columns.

2. **`overflow: hidden` on `<td>`:** Does nothing under `table-layout: auto`. Only effective with `table-layout: fixed`.

3. **`width: 1px` trick:** Only works with `table-layout: auto` (browser treats it as "shrink to content"). With `fixed`, it literally collapses to 1px.

4. **Quasar `white-space: nowrap`:** Applied globally to all table cells. This is what causes single-word filenames to force expansion — without it, the text would wrap. The truncation CSS (`white-space: nowrap; overflow: hidden; text-overflow: ellipsis`) must be on the inner content element, not just the `<td>`.

5. **Team conventions matter:** The existing column classes (`.fileSize`, `.fileType`, etc.) with their `width: 20%` values represent a team agreement on table structure. They should not be removed or modified — only the filename column's internal truncation behavior should be altered.

---

## Current state (as of 2026-05-20, session 8)

Approach: `container-type: inline-size` on table wrappers + `max-width: 40cqw` on `.fileLink` / `.fileLinkDisabled` inner text spans. Tables use default `table-layout: auto` matching `main`. Tooltip wrapping is scoped to filename slots only (not global).

| Area | Status | Key changes |
| ---- | ------ | ----------- |
| **Submissions tab** | Done | `SubmissionFilesTable.module.scss` — `container-type: inline-size`; child rows use `max-width: 40cqw` via ProceedingFileTableDataRow |
| **Client Deliverables tab** | Done | `ClientDeliverablesTable.module.scss` — `container-type: inline-size`; child rows use `max-width: 40cqw` via ProceedingFileTableDataRow |
| **Proceeding file rows** | Done | `ProceedingFileTableDataRow.module.scss` — `@include truncate-text` on `.fileLink`/`.fileLinkDisabled`; `.tooltipContent` for wrapping; `useTextTruncation` + tooltip |
| **Case Files** | Done | `CaseFileNameCell.module.scss` — `@include truncate-text` on `.fileLink`/`.fileLinkDisabled`; `.tooltipContent` for wrapping; `CaseFileNameCell.vue` — `useTextTruncation` + tooltip |
| **Global ToolTip** | Unchanged | Reverted to `main` — no global changes |

### Strategy

- `container-type: inline-size` on table wrappers makes `cqw` units resolve relative to the table's own width.
- `max-width: 40cqw` on inner `.fileLink` / `.fileLinkDisabled` text spans caps the filename at ~50% of the table container (accounting for checkbox + padding offset).
- Tables remain `table-layout: auto` (matching `main`), preserving horizontal scroll at narrow viewports and all existing column width declarations.
- Tooltip wrapping uses `max-width: 50vw` scoped to `.tooltipContent` class in each component's SCSS module — only filename tooltips wrap, not all tooltips app-wide.

---

## New code introduced

### `useTextTruncation` composable

- **Location:** `src/callisto/composables/useTextTruncation.ts`
- **Purpose:** Reactively detects whether an element's text content is visually truncated (clipped by CSS `overflow: hidden`).
- **Mechanism:** Compares `scrollWidth > clientWidth` via `@vueuse/core`'s `useResizeObserver`.
- **Returns:** `{ textRef: Ref<HTMLElement | undefined>, isTruncated: Ref<boolean> }`
- **Usage:** Bind `textRef` to the text element. When `isTruncated` is `true`, render a `<ToolTip>` with the full filename.
- **Tests:** 7 test cases in `__specs__/useTextTruncation.spec.ts`.
