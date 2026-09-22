# PRDV-16935 — Atlas Prototype: Proceeding Details Page

## Ticket

- **ClickUp:** [PRDV-16935](https://app.clickup.com/t/43227262/PRDV-16935)
- **Repo:** `proteus-front-end` (product-authoring lane; ships the Atlas UI in React/shadcn)
- **Branch:** `PRDV-16935`, cut from `prototype-main` at `f07d2e37c723e8ce2b9cb86b08212b7abb88f1f9`
- **Worktree:** `C:\Users\dustin.thomason\proteus-worktrees\PRDV-16935` (isolated — see Conflicts)
- **PR:** none — the ticket scopes this lane as a maintained prototyping branch, never merged
- **Reference (read-only):** `atlas-front-end` (visual/behavioral source of truth), `callisto-back-end`
- **Artifacts:** [PRDV-16935/](PRDV-16935/) — original ticket and the build specification
  `PRDV-16935-PROCEEDING-DETAIL-PROTOTYPE-SPEC.md`

---

## Requirements (verbatim)

> **Original Request**
> As a Product Manager, I want a realistic, clickable prototype of the existing **Atlas Proceeding Details page** using fake data, so that I can quickly create and iterate designs for new and upcoming features for stakeholders using components that will be consistent with our upcoming shadcn/react refactor work.
>
> Dev Notes:
>
> - Utilize React & Shadcn
> - Utilize "json mock server" data structures as "backend" to enable prototyping
> - (if it doesnt exist) Create a branch in proteus called "prototype-main" for this work.
>
> **Acceptance Criteria**
>
> - Shaye is able to load the prototype into claude code to make structural and design changes as needed
> - Prototype includes the following
> - Floating Action Bar — PDF page count, Media Length, File count and total size
> - All existing Tabs
> - Submission Files — All existing tracks, All existing columns in the data grid, All existing actions (select / deselect, download, delete, rename, approve)
> - Client Deliverables — Planet Suite Links, All existing columns in the data grid, All existing tracks, Deliverable Type Manager (All case, job, proceeding, track, info; pre-fill deliverable type; All existing collections; All existing deliverable types), All existing actions (select / deselect, download, delete, rename, recategorize, withdraw)
> - Client Access — All existing columns in the data grid, Add Access button, Contact Management Panel, Access Manager (All contact info, Case/job/proceeding info, All deliverable types, All warnings / case remarks)

---

## Context

- Speed and functional completeness over polish. This is a facade for product design — no backend,
  no auth, no permissions, no Azure. One permissive demo persona; all controls enabled.
- Atlas is the **visual source of truth**. Departures are allowed only where a Proteus shell
  constraint, semantic token, accessibility need, or missing shadcn primitive forces one, and each
  is recorded below.
- The repo has no test harness (`test:unit:ci` is a stub, zero spec files) and the ticket scopes
  automated tests as intentionally light.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-17 | [PRDV-16935-PROCEEDING-DETAIL-PROTOTYPE-SPEC.md](PRDV-16935/PRDV-16935-PROCEEDING-DETAIL-PROTOTYPE-SPEC.md) | `implemented` | Coordinator-authored contract wave, then five file-disjoint parallel agent packets (A mocks · B Submission Files · C Client Deliverables · D Client Access · E overview rows), then coordinator integration, one central gate, and a live-browser AC pass. |

---

## Session log

### 2026-09-18T19:10:00Z — proteus-front-end — Removed the duplicated proceeding header block

- **Problem (reported from the running page):** `/proceedings/:id` opened with the shared
  `ProceedingDetailView` — the proceeding name as an `h1` plus a meta list of date, job, ordering
  contact, location, street address, phone and proceeding id — sitting directly above the
  Case / Job / Proceeding identity rows that already carry that same identity. The name and the job
  number were on screen twice. Atlas has no such block: its page goes from the top straight into
  those three rows.
- **Solution:** Removed the *usage* from `ProceedingDetailPageContent`. **`ProceedingDetailView`
  itself is untouched** — it has two other consumers (the Schedule `ProceedingDrawer` and the Case
  Details list-view row expansion), and both were re-verified live afterwards: the drawer still
  opens and still renders "Ordering contact" / "Proceeding ID", and Case Details still shows 9 job
  links and 11 proceeding links.
- **Follow-on the removal exposed:** with that block gone the page had **no `h1` at all**. Packet E
  had deliberately rendered the proceeding name as a `div` because the removed block already
  supplied the heading. The name in the overview row now carries the heading role — verified
  `h1Count: 1`.
- Everything else re-verified unchanged on the running page: three tabs, the identity rows,
  `12 / 02 / 2026 @ 3:00 PM`, the FAB's three readouts, a full approve round trip, Client access, and
  571px at 390px wide. **Zero console errors, zero page errors.**

| Gate | Command | Result |
| ---- | ------- | ------ |
| type-check / lint / build | `npm run gate` (branch, then `prototype-main` after merge) | pass (0) both times |
| browser | Playwright/Chromium 1440×1000 + 390×844 | pass — 0 console, 0 page errors |

- **Merged and pushed:** fast-forward `04d9830` → **`4a76fa9`**, `git push origin prototype-main`
  exit 0. Two files, both under `src/pages/ProceedingDetail/`; no dependency or config change.

### 2026-09-18T18:05:00Z — proteus-front-end — Rebased onto prototype-main, deduped against shared code, merged locally

- **Problem:** `prototype-main` had moved on from this branch's base (`f07d2e3` → `e86964b`): Job
  Details landed, and both sibling tickets ran self-review passes that extracted shared code. This
  branch still carried its own copies of things that are now shared, which is exactly what a review
  flags.
- **Requirement:** Rebase onto the current tip, reuse what is already there instead of duplicating
  it, keep the gate green, and merge into `prototype-main` **locally only**.

**Rebase.** `git rebase --autostash prototype-main`. The autostash was needed because ~175 files
show as modified from a `core.autocrlf` stat-cache artifact with an empty real diff — plain `rebase`
and plain `merge` both refuse to start against it, and `git update-index --refresh` does not clear
it. Three conflicts, all resolved by keeping both sides:

| File | Conflict | Resolution |
| ---- | -------- | ---------- |
| `src/mocks/fixtures.ts` | Job Details and Proceeding Details each appended a fixture block at EOF | Kept both blocks; they are independent and neither draws from the other's PRNG stream |
| `src/mocks/routes.ts` | two import lists | Unioned |
| `src/pages/CaseDetail/components/CaseFilesTable.tsx` | `SortableTableHead` moved to `@/components`, and this branch had moved `getFileTypeLabel` to `@/lib/fileFormatting` | Took the shared `SortableTableHead` + `useTableSort`, kept the `@/lib/fileFormatting` import |

**Reuse pass — duplication removed**

- `formatJobDateTime` now comes from `@/lib/time` (the copy Case Details and Job Details already
  use). Only the missing-date fallback stays page-local, because the shared helper takes a date.
- The restricted-badge tooltip and the `Restricted` / `Restricted: U.S. Only` labels were page-local
  copies. They now read `CASE_RESTRICTION_LEVELS`, `CASE_RESTRICTION_ACCESS_LABELS` and
  `CASE_RESTRICTION_BADGE_DESCRIPTION` from `@/constants/caseRestrictions`, and level comparisons use
  the named constants instead of bare `0` / `2`.
- `CASE_RESTRICTION_BADGE_DESCRIPTION` was still page-local on Case Details while **three** pages
  render it, so it moved next to the labels it belongs with; Case Details re-exports it exactly as it
  already re-exports the labels, so its own consumer needed no change.
- **Not reused, deliberately:** `useTableSort` / `SortableTableHead`. This page ships no sort
  affordance because Atlas's `sortable` flags are inert on both of its grids (custom header/body
  slots discard them, and the deliverables rows are wrapper objects). The hook is the right one to
  reach for *if* sorting is ever added here — it is not a gap to fill now.

**Verified on `prototype-main` after the merge**, not just on the branch: three tabs, three identity
rows, `12 / 02 / 2026 @ 3:00 PM` from the shared date helper, FAB reading
`3 files, 259.37 mb` / `2 PDFs, >215 pages` / `1 file, 00:51:14`, a full approve round trip
(`approveDelta: 1`), Client access intact, and 571px at 390px wide on every tab — equal to the
`/cases` baseline. Case Details still renders `Restricted: U.S. Only` from the moved constants and
Job Details still renders its case row. **Zero console errors, zero page errors.**

- **Gates (on `prototype-main`, post-merge):**

| Gate | Command | Result |
| ---- | ------- | ------ |
| type-check | `npm run type-check` | pass (0) |
| lint | `npm run lint` | pass (0) |
| build | `npm run build` | pass (0) |
| browser | Playwright/Chromium, 1440×900 + 390×844 | pass — 0 console, 0 page errors |

- **Merge:** fast-forward, `e86964b` → `04d9830`. No fetch, no pull, no PR.
- **Push (authorized separately, after the merge was verified):** `git push origin prototype-main`,
  `0c8fa3c..04d9830`, exit 0. Local and `origin/prototype-main` now match. The push was reviewed
  first: 73 files, all under `src/`, no `package.json` / `package-lock.json` change, no secrets.

### 2026-09-18T00:20:00Z — proteus-front-end — Proceeding Details prototype built and verified

- **Problem:** Product cannot iterate on the Atlas Proceeding Details page — its tabs, grids, bulk
  actions, deliverable categorisation and client-access flows exist only in the Vue/Quasar app.
- **Requirement:** The same screen in React/shadcn on in-repo mock data: three tabs, all tracks, all
  grid columns, the floating action bar with its three readouts, and every named action.
- **Solution:** Extended the existing `src/pages/ProceedingDetail/` page (the shared
  `ProceedingDetailView` was left untouched — it has three consumers) with an Atlas-shaped identity
  block and a three-tab body, over three new typed API domains and ~30 new mock routes.

**Method.** Five read-only Atlas/Proteus recon agents first; then the architecture was decided in
writing before any code. The coordinator authored the contract (types, constants, selection hook,
tab hook, **the floating action bar**, formatting helpers) so the packets executed a fixed interface
rather than inventing one. Five implementation agents then ran in parallel on **disjoint file sets**,
forbidden from running git or any npm gate. The coordinator gated centrally, read every diff, and
verified in a real browser.

**Shipped**

- **Floating action bar** — fixed, centred, inverse-surface. `Total selected` (`2 files, 26.54 mb`),
  `PDF page count`, `Media duration`, then Deselect all / Download / Delete and an overflow menu
  carrying Rename, Approve (submission only), Recategorize (deliverables only) and Withdraw.
  Escape clears the selection; the bar is suppressed while the Deliverable Type Manager owns the flow.
- **Submission Files** — all five tracks in Atlas order, empty ones included; columns
  `File name · Size · Length · Type` with the select-all checkbox **inside** the File name header
  cell, as in Atlas; select/deselect, download, delete, rename, approve.
- **Client Deliverables** — Planet Suite links block, five columns, four tracks, collection
  subheaders with ungrouped files rendered **above** the first subheader, `Excerpt:` / `Trial Edit:`
  labels for dynamic collections, and the Deliverable Type Manager in approve and recategorize modes.
- **Client access** — three columns plus an `sr-only` kebab column, `Add access`, the contact search
  panel (Enter-to-search, matching Atlas's no-debounce behaviour), and the Access Manager with the
  full track → collection → deliverable-type toggle tree, Planet Suite block, and the four
  warning/remarks sections.
- **Pre-fill (an explicit AC)** — the collection defaults to `Full Transcript` / `MP4 Video`, and
  each file's deliverable type auto-selects from its filename (`.txt` → `ASCII`,
  `.pdf` → `Full Size PDF`, verified live).

**Defects found in the browser and fixed**

- **Narrow-viewport overflow.** All three tabs measured 639px at a 390px viewport against a
  571px `/cases` baseline. Diagnosed by listing elements that exceed the viewport **and** are not
  clipped by an `overflow-x` ancestor: the single contributor was the tab strip, whose three
  triggers cannot fit. Made the strip itself scrollable; all three tabs now measure **571 — exactly
  the shell baseline**. The residual 571 is the pre-existing app-shell header, not this page.
  No magic constants.
- **Identity rows could not shrink** — a flex item defaults to `min-width: auto`, so a long case
  name pushed the row past the viewport. Added `min-w-0`.
- **`.wav` rendered as Type `File`** — the file-type label map lacked the common audio/video
  extensions. Added them.

**Coordinator corrections to agent output** (each invisible to the agent, which was barred from gates)

- **Packet C died mid-refactor** (spend limit) leaving `DeliverableTypeManagerDrawer.tsx`
  uncompilable: a lost `useEffect` import and dangling `isCancelConfirmOpen` / `onCancel`
  references from a half-moved cancel guard. Completed the refactor the way it was heading — the
  unsaved-edits guard now lives in the drawer so **backdrop and Escape are guarded too**, not just
  the Cancel button, with the form kept mounted (`hidden`) so "keep editing" cannot discard the very
  edits the guard protects.
- **Packet A died mid-verification**, leaving three `proceedingId: number | null` type errors. The
  seed type admits null only because the API's `Proceeding.proceedingId` does; narrowed once in the
  eager build rather than threading a nullable id through every builder.
- A `flatMap` whose two branches inferred `label: null` and `label: string` could not unify —
  pinned the element type.
- Fixed **my own specification error**: I had specified `Badge variant="outline"` for the restriction
  badge. Packet E flagged that Atlas tints it red and the sibling Case Details page renders the same
  concept as a toned `StatusPill`. Restriction is an alert state, not a muted one — switched to
  `StatusPill`, matching both.
- `npm run lint:fix` for `object-shorthand` and import order across four files.

**Deliberate departures from Atlas** (each forced, each recorded in code)

| Departure | Why |
| --------- | --- |
| Access Manager and Deliverable Type Manager are `Drawer`s, not centred modals | No `dialog` primitive exists; adding one needs a dependency change, which the ticket forbids |
| No toast system — bulk outcomes render inline, drawer failures render in-drawer | No toast exists anywhere in the app and `sonner` is not installed |
| Case remarks render as plain text | Atlas sends sanitized HTML; no sanitizer is installed, so rendering raw HTML would be unsafe |
| Selection uses native `<input type="checkbox">`, selects are native `<select>`, Access Manager toggles are `<button role="switch">` | No checkbox/select/switch primitives exist. The toggle is what Atlas itself does, so that one is parity |
| Delete on the action bar carries its destructive meaning by icon + hover fill rather than a red label | A red label does not clear AA on the inverse-surface bar |
| Byte format matches Atlas exactly (`2.50 kb`) | The FAB readout is a stated AC. Case Details keeps its own `178.1 KB` and was not touched, so the two pages format sizes differently — accepted and recorded |
| Contact panel closes when a contact is picked | Atlas layers both; two stacked bottom-sheet drawers are not viable |
| Per-collection eligible types | Proteus's `DeliverableCollection` has no `eligibleTypes` field, so a collection offers all of its track's types |

**Deliberately out of scope** (present in Atlas, named by no AC): Planet Summary generate/cancel/
retry, Show/Hide original expansion rows and lineage badges, drag-and-drop upload and real upload
transport, dynamic-collection deletion, proceeding rename/delete, and all permission/restriction
gating.

**Not ported, on purpose:** Atlas sets `sortable: true` on the file-name column of both grids, but
its custom header/body slots discard it and the deliverables rows are wrapper objects, so **sorting
is inert in Atlas**. Porting a sort control would have been inventing a feature, so there is none.

- **Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | `proteus-front-end` | fail (exit 1) — **waived by the ticket owner** | **Pre-existing, not introduced.** 4 advisories (2 high, 2 moderate): `hono`, `js-yaml`, `qs` all transitive under `shadcn@4.18.0` (a scaffolding CLI never imported by app code), `fast-uri` under `@hookform/resolvers`→`ajv` (the app validates with Zod). `git diff` on `package.json`/`package-lock.json` is **empty** — no dependency or lockfile change was made, and the ticket forbids one, so `npm audit fix` was not run. Waived on 2026-09-18 after review; residual risk is unpatched build-tooling transitives absent from the shipped browser bundle. |
| lint | `npm run lint` (after `lint:fix`) | `proteus-front-end` | pass (exit 0) | — |
| type-check | `npm run type-check` (`tsc -b`) | `proteus-front-end` | pass (exit 0) | — |
| build | `npm run build` | `proteus-front-end` | pass (exit 0) | pre-existing >500 kB chunk warning only |
| browser | Playwright/Chromium 1440×900 + 390×844 | all 3 tabs, `/proceedings/:id`, `/jobs/:id`, `/cases/1`, `/schedule` | pass | **0** console errors, **0** page errors across every flow |

- **Tests added/updated:** none — **exception applies.** The repo has no runnable harness
  (`test:unit:ci` is a stub; zero `*.spec.*` files under `src/`) and the ticket scopes tests as
  intentionally light. Behaviour was verified end-to-end in a real browser instead. Residual risk:
  no regression net for `formatBytes`, `formatMediaDuration`, the PDF/media selection summaries, or
  the deliverable-type auto-select rules. Smallest follow-up that would unlock coverage: wire a
  Vitest config and start with those four pure functions in `src/lib/fileFormatting.ts` and
  `src/pages/ProceedingDetail/utils.ts`.
- **Regression impact:** `ProceedingDetailView` and `ProceedingDrawer` were **not** modified; both
  other consumers were re-verified live (Schedule drawer opens; Case Details list view intact, 9 job
  links and 8 proceeding links). `getFileExtension`/`getFileTypeLabel` were promoted from
  `CaseDetail/hooks/caseFileFormatting.ts` to `src/lib/fileFormatting.ts` (a second page now needs
  them) and the three CaseDetail importers updated; the Case Files tab was re-verified and still
  renders `178.1 KB` and `PDF Document`.
- **API docs — not relevant:** this repo exposes no Swagger/OpenAPI surface; searched for `swagger`,
  `@Api` and `openapi` and found none. The mock route table in `src/mocks/routes.ts` is the only
  contract artifact and it was updated alongside every new endpoint.
- **Approve verified end-to-end**, not just opened: selecting a submission file → overflow →
  `Approve all selected` → manager pre-filled `Full Transcript (default)` / `ASCII` → Submit closes
  the manager, the row gains the approved bookmark on Submission Files, and it appears on Client
  Deliverables (`countDelta: 1`). An earlier run appeared to show approve doing nothing; that was a
  flaw in the probe — mock mutations are session-local module state and the probe was switching tabs
  with `page.goto`, which reloads the app and resets them. Re-run with tab clicks, it passes.

---

## Conflicts / exceptions

- **Shared-checkout collision.** Partway through setup, a parallel session created `PRDV-16934`
  (Job Detail) and checked it out in the single `proteus-front-end` working tree, which this session
  then switched away from. Both branches sat at the same SHA with a clean tree, so nothing was lost.
  The main checkout was restored to `PRDV-16934` and this ticket moved into a dedicated git worktree.
  **Lesson for this ticket family: cut the worktree before the first git command, not after.**
- **Two agents were killed mid-flight by a spend limit** (packets A and C). Both had written all
  their files; C's had a broken half-refactor. Recovered by the coordinator rather than re-running
  the agents — see the corrections above.
- **Duplicate mutation hooks — resolved against Callisto, and it was not cosmetic.** Packets B and C
  each defined `useRenameProceedingFile`, `useDeleteProceedingFiles`, `useDownloadProceedingFiles`,
  `useWithdrawProceedingFiles` and `useApproveProceedingFiles` in their own module with different
  signatures. Rather than pick on style, the two were judged against the back end:
  - `POST /granting-client-access/v2/approve-files-for-delivery` accepts
    `pendingDynamicCollectionName` and its service creates the collection as part of the request
    (`approve-deliverable-files-v2.service.ts`). So approve **can** change the dynamic-collection
    list, and C's extra `dynamicCollectionsQueryKey` invalidation is **required**, not redundant —
    B's omission was wrong.
  - `RecategorizeDeliverableFileItemDTO.trackTypeId` is documented as "Must match
    destinationTrackTypeId". C's approve maps each file onto the **destination** track the user
    picked; B's sent the file's **source** track. The integration was wired to B's, so approving
    onto a different destination collection would have filed it under the wrong track. **This was a
    live functional defect, found only by checking Callisto** — a green gate and a working-looking
    UI both missed it.
  
  C's implementations are now the single copy, living in the sensibly-named
  `useProceedingFileMutations.ts`; `useDeliverableMutations.ts` imports them and keeps only
  recategorize and the Planet Suite link mutations. `DeliverableManagerSubmitPayload` moved to the
  page's `types.ts` so neither module owns the other's contract. Re-gated and re-verified.

---

## Current state (as of 2026-09-18)

- **Merged into `prototype-main` and pushed.** `prototype-main` is at **`4a76fa9`** on both local and
  `origin`, carrying `65f3cbc` "Add Proceeding Details prototype page", `04d9830` "Reuse shared
  restriction and date helpers" and `4a76fa9` "Drop duplicated proceeding header block". The checkout
  is clean and the gate is green there.
- The push carried **4** commits, not 2: the two Job Details commits (`388e649`, `e86964b`) were
  already on local `prototype-main` when this branch merged into it, so publishing the branch
  published them too. No PR was opened and nothing was fetched or pulled.
- The `PRDV-16935` branch still exists (rebased, same tip) in its worktree at
  `C:\Users\dustin.thomason\proteus-worktrees\PRDV-16935`.
- Every ticket AC is demonstrably satisfied on the running page, verified in Chromium at 1440×900
  and 390×844 with **zero console and zero page errors**, including a full approve round trip
  (Submission Files → Deliverable Type Manager → Client Deliverables).
- The audit exception is waived and recorded above; no dependency or lockfile change was made.

---

## Key technical learnings

- **A green gate still says nothing about a working page.** Type-check, lint and build were all
  green while the tab strip pushed every page 68px past the viewport at phone width, and while
  `.wav` rendered as `File`. Browser observation is what found both.
- **Find the element that actually grows the document.** Listing everything past the viewport edge
  is noise — the shadcn `Table` is legitimately 807px wide inside its own `overflow-x-auto` wrapper.
  Filtering to elements *not* clipped by an `overflow-x` ancestor collapsed a 31-element list to one
  real culprit.
- **An agent that cannot run gates cannot catch what gates catch**, and an agent that dies mid-edit
  leaves code that looks finished. Both of this session's failed packets had written every file.
  Central verification is not overhead; it is the only thing that caught either.
- **Brief the agents with the measured evidence, not just the instruction.** The `>215 pages` /
  `> 00:51:14` prefix asymmetry, the checkbox living inside the File name header cell, and the
  "ungrouped files render above the first subheader" rule all survived into the build because the
  prompts carried the measurement rather than a summary.
