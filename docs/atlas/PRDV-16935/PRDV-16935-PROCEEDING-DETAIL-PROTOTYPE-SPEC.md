# PRDV-16935 — Atlas Proceeding Details Prototype — Build Specification

**Author:** coordinator agent · **Created:** 2026-09-17
**Repo:** `proteus-front-end` · **Worktree:** `C:\Users\dustin.thomason\proteus-worktrees\PRDV-16935`
**Branch:** `PRDV-16935` · **Base SHA:** `f07d2e37c723e8ce2b9cb86b08212b7abb88f1f9` (tip of `prototype-main`)
**Baseline gate:** `npm run gate` → **exit 0** before any edit.

This artifact owns every architecture and design decision. Implementation agents execute it and
**stop and report** rather than inventing a decision it omits.

---

## 0. Collision notice (recorded, resolved)

The single `proteus-front-end` checkout was taken by a parallel session on branch `PRDV-16934`
(Job Detail) mid-session. This ticket therefore runs in a **separate git worktree**. The main
checkout was returned to `PRDV-16934` untouched; both branches sat at the same SHA with a clean
tree, so nothing was lost. **No agent on this ticket runs any git command.**

---

## 1. Problem → Requirement → Solution

**Problem.** Product needs to iterate on the Atlas Proceeding Details page — its tabs, file grids,
bulk actions, deliverable categorisation and client-access flows — but that page exists only in the
Vue/Quasar app, which product cannot safely prototype against.

**Requirement.** A clickable React/shadcn Proceeding Details page in Proteus that, viewed beside
Atlas, reads as the same screen: the same three tabs, the same tracks, the same grid columns, the
same floating action bar with its three metadata readouts, and the same actions — running entirely
on in-repo mock data, with no backend, auth, permissions or Azure.

**Solution.** Extend the existing `src/pages/ProceedingDetail/` page (do **not** replace it, do not
touch the shared `ProceedingDetailView`) with an Atlas-shaped overview + 3-tab body, backed by three
new typed API domains and mock routes, built in one coordinator-authored contract wave and five
parallel file-disjoint agent packets.

---

## 2. Scope — what the ACs resolve to

Ticket ACs, resolved against the Atlas source:

| AC | Resolution |
| --- | --- |
| Floating Action Bar | Fixed, centred, dark bar. Blocks: Total selected · PDF page count · Media duration · Deselect all · Download · Delete · overflow kebab |
| PDF page count | FAB block 2, `1 PDF, {n} pages` / `{c} PDFs, {n} pages`, `>` prefix (no space) on mixed availability, `—` when none known |
| Media Length | FAB block 3, `1 file, {d}` / `{c} files, {d}`, `d` = zero-padded `HH:MM:SS`, `> ` prefix (**with** space) on mixed, `—` when none known |
| File count and total size | FAB block 1, `Total selected` / `3 files, 15.30 mb` |
| All existing Tabs | Exactly **three**: Submission Files · Client Deliverables · Client access. **No count badges** (Atlas has none) |
| Submission Files | 5 tracks, 4 columns, select/deselect, download, delete, rename, approve |
| Client Deliverables | Planet Suite Links, 5 columns, 4 tracks + collection grouping, Deliverable Type Manager, select/deselect, download, delete, rename, recategorize, withdraw |
| Client Access | 3 columns + row kebab, Add access, Contact Management Panel, Access Manager (contact info, case/job/proceeding info, all deliverable types, warnings + case remarks) |

### Deliberately excluded (recorded, not forgotten)

Present in Atlas, **not** named by any AC, and omitted to keep this prototype deliverable:

1. Planet Summary generation / cancel / retry, and the derivation status lines on a file row.
2. Show/Hide **original** expansion rows and the `Original` / `Converted` lineage badges.
3. Drag-and-drop upload, the `TrackSelectorForm` destination picker, and all real upload transport.
4. Dynamic-collection **deletion** from the collection subheader menu.
5. Proceeding rename/delete from the overview kebab.
6. All permission/restriction gating — the prototype runs one permissive persona, so every control
   is enabled. Atlas's `canGrant` / `canRevoke` / restricted-job tooltips are not modelled.

---

## 3. Binding decisions

**D1 — Byte format matches Atlas exactly.** New `formatBytes`: base 1024, **lowercase** units
`b kb mb gb tb`, integers with no decimals (`500 b`), non-integers with exactly 2 (`2.50 kb`),
`bytes <= 0` → `'0 b'`. The Case Details page keeps its existing `178.1 KB` `formatFileSize` and is
**not** touched; the two pages will therefore format sizes differently. That inconsistency is
accepted because the FAB readout is an explicit AC and Atlas is the source of truth here.

**D2 — No sort affordance anywhere on this page.** Atlas sets `sortable: true` on `fileName` in both
grids, but the custom `#header`/`#body` slots discard it and the deliverables rows are wrapper
objects, so `field` cannot resolve. Sorting is **inert in Atlas**; porting a sort control would be
inventing a feature. `SortableTableHead` is therefore **not** needed and **not** promoted.

**D3 — Every overlay is a `Drawer`.** No `dialog`, `alert-dialog`, `sheet` or `select` primitive
exists, and `npx shadcn add` is forbidden (no dependency or lockfile changes). The Case Details
precedent already implements confirmations as Drawers (`CaseFileDeleteDrawer`). Atlas's
Contact Management Panel is itself a 400px right drawer — exact match. Atlas's Access Manager is a
centred 960px two-column modal and its Deliverable Type Manager a 715px modal; both become Drawers.
**Recorded departure, forced by a missing primitive.**

**D4 — Selection controls are native `<input type="checkbox">`,** styled
`size-4 rounded border-input accent-primary`, exactly as `CaseFilesTable` already does. No checkbox
primitive exists.

**D5 — Access Manager toggles are `<button role="switch" aria-checked>`.** This is precisely what
Atlas does (`AccessManagerToggle.vue` is a custom button, not a q-toggle), so it is parity, not a
workaround.

**D6 — Selects are native `<select>`** styled with Tailwind tokens. Consistent with D4's native
precedent. No select primitive exists.

**D7 — No toast system.** None exists anywhere in the app and `sonner` is not installed. Atlas
toasts every mutation. Replacement: mutations that run from a Drawer show their error **inline in
that Drawer** and close on success; bulk actions fired from the FAB (download, withdraw, delete,
approve) surface a transient inline `Alert` above the tab content. **Recorded departure.**

**D8 — Tab state lives in `?tab=`,** read/written with `useSearchParams` and `{ replace: true }`,
validated against the tab list with fallback to `submission-files` — the `useCaseDetailTab` pattern.
Atlas uses raw `history.replaceState`; `replace: true` is the faithful React equivalent.

**D9 — Both `/proceedings/:proceedingId` and `/jobs/:jobId` render this page today** and must keep
working. The page already discriminates on `useParams`. Nothing in the router changes on this
ticket. Job Detail is a different ticket (`PRDV-16934`) — do not touch `src/app/router/index.tsx`.

**D10 — `ProceedingDetailView` and `ProceedingDrawer` are untouchable.** They have three consumers
(this page, `ProceedingDrawer` → Schedule, `CaseDetailListView` row expansion). All new page chrome
lives under `src/pages/ProceedingDetail/`. The current page body (breadcrumb + `ProceedingDetailView`)
is **kept above** the new Atlas-shaped sections, because it is the Proteus shell's established
detail-page header and removing it would break the breadcrumb.

**D11 — Track/collection/deliverable-type catalogues are API-shaped, not hardcoded in components.**
They come from mock routes, exactly as the real Callisto endpoints do.

**D12 — FAB colour.** Atlas uses `$schemes-inverse-surface` (#313030). The Proteus token equivalent
is `bg-foreground text-background`. Destructive action uses `text-destructive`; **contrast on the
dark bar must be verified in the browser pass** and downgraded to a neutral treatment if it fails.

---

## 4. Atlas facts the build must honour

**Tracks — Submission Files** (order is the render order):
`Transcript(2) · Exhibits(1) · Audio(5) · Video(3) · MVC(4)`. All five render even when empty
(name greyed, badge `0`, no table). Track labels are raw strings, never translated.

**Tracks — Client Deliverables:** `Transcript · Exhibits · Video · MVC` only. `Audio` and
`Planet Suite` are deliberately excluded from the grid.

**Static collections:** Transcript → `Full Transcript`, `Redacted`; Video → `MP4 Video`,
`MPEG Video`; Exhibits and MVC have none. Dynamic collections exist for Transcript (“excerpt”
vocabulary) and Video (“trial edit”) only.

**Deliverable types** (exact `value` strings, by track):
- Exhibits: `Exhibit`, `Other`
- MVC: `Audio`, `Other`, `Zoom Recording`
- Transcript: `ASCII`, `Certificate/Filing Notice`, `Condensed PDF`, `Errata Sheet - Blank`,
  `Errata Sheet - Signed`, `Full Size PDF`, `Index Pages`, `LEF (LiveNote)`,
  `No Index - Condensed PDF`, `No Index - Full Size PDF`, `Other`, `PDF Portfolio`,
  `PDF with Exhibits`, `PTX (E-transcript)`, `PTZ (Case Notebook)`, `Planet Summary`,
  `Read Only PDF`, `Rough Draft`, `SBF (Summation)`, `Word Document`, `XMEF (TextMap)`
- Video: `CMS (Trial Director)`, `DepoView`, `LEF (LiveNote)`, `MDB (Sanction)`, `Other`,
  `PTZ (Case Notebook)`, `SBF (Summation)`, `Subtitles (SMI)`, `Video`, `Viewer`, `XMEF (TextMap)`
- Planet Suite: `Planet Draft`, `Planet Sync`

**`length` is one field with two meanings:** page count for `.pdf`, seconds for a media extension,
otherwise not displayed. Row cell shows `{n} pages`, `HH:MM:SS`, or `—`.

**Columns — Submission Files:** `File name` · `Size` · `Length` · `Type`. The select-all checkbox
lives **inside the `File name` header cell**; the row checkbox inside the `File name` body cell.
There is no separate checkbox column and no row kebab.

**Columns — Client Deliverables:** `File name` · `Deliverable type` · `Size` · `Length` ·
`File type`. Ungrouped files render **above** the first collection subheader with no header of their
own; collection subheaders sort by collection id ascending.

**Columns — Client Access:** `Contact` (full name + contact type beneath) · `Firm` (name + street +
`city, state`) · `Contact email` · a 56px unlabeled kebab column. Row menu has exactly one item:
`Edit access`.

**Access Manager save rule:** save is enabled only when dirty **and** (something is selected **or**
the contact has been saved before) — an all-empty first-time selection cannot be saved, but clearing
a previously-saved set can.

**Deliverable Type Manager pre-fill:** the collection defaults to `Full Transcript` (Transcript) or
`MP4 Video` (Video); each file's deliverable type is auto-selected from its filename/extension. Both
are the “pre-fill deliverable type” AC.

---

## 5. Target file tree

```
src/lib/fileFormatting.ts                         ← NEW (wave 0)
src/api/proceeding-files/{.types.ts,.api.ts}      ← NEW (wave 0)
src/api/deliverables/{.types.ts,.api.ts}          ← NEW (wave 0)
src/api/client-access/{.types.ts,.api.ts}         ← NEW (wave 0)
src/api/index.ts                                  ← EDIT (wave 0)
src/pages/ProceedingDetail/
├── types.ts                                      ← EDIT (wave 0)
├── constants.ts                                  ← EDIT (wave 0)
├── hooks/
│   ├── useProceedingDetail.ts                    ← untouched
│   ├── useProceedingFileSelection.ts             ← NEW (wave 0)
│   ├── useProceedingDetailTab.ts                 ← NEW (wave 0)
│   ├── useProceedingFiles.ts                     ← B
│   ├── useProceedingFileMutations.ts             ← B
│   ├── useProceedingDeliverables.ts              ← C
│   ├── useDeliverableCatalog.ts                  ← C
│   ├── useDeliverableMutations.ts                ← C
│   ├── useClientAccess.ts                        ← D
│   └── useAccessManager.ts                       ← D
└── components/
    ├── ProceedingDetailPageContent.tsx           ← EDIT (wave 2, coordinator)
    ├── ProceedingFilesActionBar.tsx              ← NEW (wave 0) — the FAB
    ├── ProceedingActionFeedback.tsx              ← NEW (wave 0)
    ├── SubmissionFilesPanel.tsx                  ← B
    ├── SubmissionFilesTrackSection.tsx           ← B
    ├── ProceedingFileRow.tsx                     ← B
    ├── ProceedingFileRenameDrawer.tsx            ← B
    ├── ProceedingFileDeleteDrawer.tsx            ← B
    ├── ClientDeliverablesPanel.tsx               ← C
    ├── ClientDeliverablesTrackSection.tsx        ← C
    ├── PlanetSuiteLinksSection.tsx               ← C
    ├── DeliverableTypeManagerDrawer.tsx          ← C
    ├── ClientAccessPanel.tsx                     ← D
    ├── ContactManagementDrawer.tsx               ← D
    ├── AccessManagerDrawer.tsx                   ← D
    ├── AccessManagerToggle.tsx                   ← D
    ├── AccessManagerWarningsPanel.tsx            ← D
    ├── ProceedingInfoRow.tsx                     ← E
    ├── ProceedingCaseInfo.tsx                    ← E
    ├── ProceedingJobInfo.tsx                     ← E
    └── ProceedingOverviewBlock.tsx               ← E
src/mocks/fixtures.ts                             ← A
src/mocks/routes.ts                               ← A
```

---

## 6. Packet ownership (disjoint — this is the collision contract)

| Packet | Owner | Exclusive files |
| --- | --- | --- |
| **Wave 0** | coordinator | `src/lib/fileFormatting.ts`, all three `src/api/<domain>/*`, `src/api/index.ts`, page `types.ts`, `constants.ts`, `useProceedingFileSelection.ts`, `useProceedingDetailTab.ts`, `ProceedingFilesActionBar.tsx`, `ProceedingActionFeedback.tsx` |
| **A** | agent | `src/mocks/fixtures.ts`, `src/mocks/routes.ts` |
| **B** | agent | `SubmissionFilesPanel/TrackSection`, `ProceedingFileRow`, `ProceedingFileRenameDrawer`, `ProceedingFileDeleteDrawer`, `useProceedingFiles`, `useProceedingFileMutations` |
| **C** | agent | `ClientDeliverablesPanel/TrackSection`, `PlanetSuiteLinksSection`, `DeliverableTypeManagerDrawer`, `useProceedingDeliverables`, `useDeliverableCatalog`, `useDeliverableMutations` |
| **D** | agent | `ClientAccessPanel`, `ContactManagementDrawer`, `AccessManagerDrawer`, `AccessManagerToggle`, `AccessManagerWarningsPanel`, `useClientAccess`, `useAccessManager` |
| **E** | agent | `ProceedingInfoRow`, `ProceedingCaseInfo`, `ProceedingJobInfo`, `ProceedingOverviewBlock` |
| **Wave 2** | coordinator | `ProceedingDetailPageContent.tsx` |

No two packets share a file. B/C/D **consume** wave-0 files (FAB, selection hook, formatting, API
types) but never edit them. If a packet believes it must edit a file outside its list, it **stops
and reports** the file, symbol and reason.

---

## 7. Rules binding every implementation agent

- Read `AGENTS.md`, `PRODUCT.md`, `DESIGN.md` and `.cursor/rules/*.mdc` before editing.
- **No git. No `npm run gate` / `lint` / `build` / `dev` / `install`.** They contend over `dist/`
  and `tsbuildinfo`. The coordinator gates centrally, once.
- Edit only the packet's files. Create no others.
- Data only through `src/api/**` + a TanStack Query hook. **Never** import a fixture, never branch
  on mock mode, never hardcode data in a component.
- Hooks own queries/mutations; components are presentational. Split a component over ~150 lines.
- Tailwind utilities + semantic tokens only. No raw hex, no `bg-[#…]`, no inline `style`, no CSS
  Modules, no `dark:` overrides, no second UI library, no new `components/ui/` file.
- TypeScript: `import type`, no `any`, no `enum`, `as const`. Named arrow exports, one component per
  file, no page barrels — import explicit paths.
- ESLint style is enforced: sorted imports, blank line before `return`, no `console.log`.
- Reproduce the Atlas structure recorded in §4 and in your packet brief. Record any material visual
  departure and the concrete Proteus constraint that forced it. Make no unrequested design
  improvements.
- Stop and report on any missing decision instead of improvising one.

---

## 8. Verification plan (coordinator)

1. Central `npm run gate` after all packets land (type-check → lint → build).
2. Read **every** diff personally; agent reports are not evidence.
3. AC-by-AC pass, one header per AC, defects enumerated with `file:line` on both sides.
4. Live browser pass (Playwright + cached Chromium at
   `…/ms-playwright/chromium-1228/chrome-win64/chrome.exe`) at 1440×900 and 390×844, covering every
   tab, both routes, the FAB with a mixed PDF/media selection, and each drawer. Console and page
   errors must be zero.
5. Re-check `/cases/:caseId` Jobs-tab links still navigate here, and that Schedule's
   `ProceedingDrawer` still renders — the two `ProceedingDetailView` consumers at risk.
6. Fix, re-gate, re-verify. Then `npm audit --audit-level=high` → lint → build, **unpiped**, with
   true exit codes, before any commit.
