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

## Session log

_Newest first. Older debugging detail lives in **Attempt history** below._

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

## Current state (as of 2026-05-20)

### Narrowed scope — ProceedingFileTableDataRow only

After testing, all changes outside of `ProceedingFileTableDataRow` have been **reverted to `main` state**. The current branch focuses exclusively on:

- `ProceedingFileTableDataRow.module.scss` — `overflow: hidden` on `.fileName`, truncation styles on `.fileLink`/`.fileLinkDisabled`
- `ProceedingFileTableDataRow.vue` — `useTextTruncation` composable integration, conditional `<ToolTip>`
- `useTextTruncation.ts` — new composable for reactive truncation detection
- `useTextTruncation.spec.ts` — 7 unit tests

### Pending — future updates

The following areas need the same treatment but have not been tested yet and will be addressed separately:

| Area | File(s) | Status |
| ---- | ------- | ------ |
| **Case Files** | `CaseFilesTable.module.scss`, `CaseFilesTable.vue`, `CaseFileNameCell.vue` | Reverted to `main` — update pending |
| **Submissions tab** | `SubmissionFilesTable.module.scss` (parent table for ProceedingFileTableDataRow) | Reverted to `main` — `table-layout: fixed` needed here for row widths to be enforced |
| **Client Deliverables tab** | `ClientDeliverablesTable.module.scss` (parent table for ProceedingFileTableDataRow) | Reverted to `main` — `table-layout: fixed` needed here for row widths to be enforced |

### Important note on parent tables

`ProceedingFileTableDataRow` is a **row component** rendered inside `SubmissionFilesTable` and `ClientDeliverablesTable`. The column width percentages (`.fileName { width: 40% }`, `.fileSize { width: 20% }`, etc.) defined on the row's `<td>` elements are only enforced when the **parent table** uses `table-layout: fixed`. Without that addition on the parent tables, the widths remain hints and the original bug may persist. This dependency should be addressed when those parent tables are updated.

---

## New code introduced

### `useTextTruncation` composable

- **Location:** `src/callisto/composables/useTextTruncation.ts`
- **Purpose:** Reactively detects whether an element's text content is visually truncated (clipped by CSS `overflow: hidden`).
- **Mechanism:** Compares `scrollWidth > clientWidth` via `@vueuse/core`'s `useResizeObserver`.
- **Returns:** `{ textRef: Ref<HTMLElement | undefined>, isTruncated: Ref<boolean> }`
- **Usage:** Bind `textRef` to the text element. When `isTruncated` is `true`, render a `<ToolTip>` with the full filename.
- **Tests:** 7 test cases in `__specs__/useTextTruncation.spec.ts`.
