# PRDV-16047 — Changelog

**Ticket:** [PRDV-16047 — ClickUp](https://app.clickup.com/t/43227262/PRDV-16047)
**System:** atlas · **Repo:** `atlas-front-end` · **Branch:** `PRDV-16047`
**Type:** Bug / defect (frontend-only) · **Estimate:** 3 pts (refinement)

---

## Requirements (verbatim)

> # User sees withdraw option in menu from all tracks when no access - PRDV-16047
>
> ## Roles
> - Neptune_Facilities
> - Neptune_Accounts_Receivable
> - Other roles that have partial permissions
>
> ### Actual Result
> Withdraw option is enabled but user can not withdraw files from all tracks. (you can click on withdraw but actually receive an error from BE)
>
> ### STR
> 1. Assign only Neptune_Facilities
> 2. Open any unrestricted proceeding where files exist in every track (Submission files or Client deliverable)
> 3. Find an approved file (by other role with access) in Transcript/Video/MVC/Audio track
> 4. Select file
> 5. Open menu in Transcript/Video/MVC/Audio track
>
> ### Expected Result
> User sees withdraw files option active only for allowed track in permissions
>
> ---
>
> ## Bug Fix: Gate Unauthorized Frontend Withdrawal Options
>
> **Objective:** Align the frontend "withdraw" menu option with existing backend authorization by dynamically hiding or disabling the UI element for all roles with partial or no withdrawal permissions across all system tracks.
>
> **Problem:** Users with roles that have partial or no withdrawal permissions are incorrectly presented with a visible and clickable "withdraw" option in the UI menu across all system tracks. When these unauthorized users click the button, the backend correctly rejects the action and returns an error. The frontend fails to dynamically gate the UI element based on user permissions, creating an "illusion of access".
>
> **Requirement:** The "withdraw" menu option must be dynamically hidden or disabled for any user who does not possess explicit authorization to perform withdrawals. This gate must apply globally to all user roles with partial or no withdrawal permissions.
>
> **Solution:** Conditionally render or disable the shared component responsible for rendering the "withdraw" menu option. Leverage existing user permission state and evaluate it against the system's authoritative permission rules. Introduce a dynamic capability check in the shared UI rendering path — do not hardcode role IDs.
>
> **Constraints / Non-goals:** Do not modify backend authorization logic or introduce new backend API endpoints — the backend already correctly validates permissions and rejects unauthorized attempts.
>
> **Open Questions:**
> 1. Is there an existing centralized frontend permission service/utility that can be queried, or must the component manually evaluate the user's role DTO?
> 2. Should the UI default to hiding the unauthorized "withdraw" option entirely, or displaying it as disabled with an explanatory tooltip?
>
> **Estimate:** 3 points

---

## Context

- Refinement (scrum transcript `docs/atlas/16047/transcript.txt`): scope is **any role with partial
  permissions**, not one role; the fix is **frontend-only** ("you can click on withdraw, but
  actually receive an error from back end"); estimate **3 pts**; the linked permissions sheet is the
  product reference (backend guards are the authoritative enforcement).
- Sibling PRDV-16185 (upload button shown on restricted cases without access) is the same *class* of
  bug but a **separate ticket** — out of scope here.

## Current state

- On branch `PRDV-16047` (off `main`).
- **Root cause proven** (read-only investigation, atlas-front-end + callisto-back-end) and captured
  in `docs/atlas/16047/PRDV-16047-code-investigation.md`.
- **Spec** in review — larry-adams [PR #13](https://github.com/planetdepos/larry-adams/pull/13).
- **Implementation complete** on branch `PRDV-16047` (atlas-front-end): centralized
  `canWithdrawApproval` capability gating all three withdraw entry points; hide-on-no-permission;
  audio disabled+tooltip preserved; Approve untouched. All gates green (audit / lint / type-check /
  146 tests). Implemented ahead of spec sign-off at the user's request; still to be reviewed against
  spec PR #13 before merge.
- **Atlas PR:** [planetdepos/atlas-front-end#530](https://github.com/planetdepos/atlas-front-end/pull/530)
  — commit `57cbd7e58800486133072cd57f4ada54c2f4ef8f`; reviewer `daedalus1215` (Larry). Manual UI
  repro per STR + screenshots pending.

## Plans

| Date | Plan / path | Status | Approach |
| ---- | ----------- | ------ | -------- |
| 2026-07-02 | Code investigation — `docs/atlas/16047/PRDV-16047-code-investigation.md` | reference | Proven root cause (resource-key drift) + verification plan/results |
| 2026-07-02 | Design plan — Claude Code plan file (`~/.claude/plans/forgot-to-put-you-enchanted-salamander.md`) | implemented | Centralized `canWithdrawApproval` (client-deliverable `create`) gate on all 3 withdraw entry points; hide on no-permission; preserve audio disabled+tooltip — see Session log 2026-07-02T04:23:33Z |
| 2026-07-02 | Story spec (canonical) — `larry-adams/systems/neptune/permissions/PRDV-16047-gate-unauthorized-withdraw-approval.md` — [PR #13](https://github.com/planetdepos/larry-adams/pull/13) | in review | Bug-fix format matching Larry's own PRDV-16144 template; PR opened, `daedalus1215` (Larry) requested as reviewer |

## Attempt history

_(none yet)_

## Session log

### 2026-07-02T04:23:33Z — atlas-front-end (implementation + tests)

Implemented the fix on branch `PRDV-16047`:

- **`useProceedingFilePermission.ts`** — added `canWithdrawApproval(files)` = deliverable-scoped
  `create` (all-tracks), mirroring the backend `MultiDeliverableFileAuthorizeRole`.
- **`ProceedingFileRowActionsMenu.vue`** — added `canWithdrawApproval` to
  `ProceedingFileRowMenuPermissions`; both withdraw items (single + batch) now gate on it. The
  `v-if` hides the item on lack of permission while keeping the audio special-case visible, so the
  existing "cannot withdraw audio files" disabled+tooltip is unchanged.
- **`SubmissionFilesTable.vue`** — supplies `canWithdrawApproval` in `hasPermissionForSelectedFiles`
  (fixes the submission-resource drift) and exposes a selection-scoped `canWithdraw` computed.
- **`ClientDeliverablesTable.vue`** — supplies `canWithdrawApproval` in
  `hasPermissionForSelectedFiles` and `getRowPermissions` (value unchanged, now single-sourced);
  exposes `canWithdraw`.
- **`ProceedingDetailPage.vue`** — FAB `withdraw-approval` action now `disabled: !ref?.canWithdraw`
  (was state-only), closing the ungated path.
- **Approve gating unchanged** (submission resource — proven correct).

Files: `useProceedingFilePermission.ts`, `ProceedingFileRowActionsMenu.vue`,
`SubmissionFilesTable.vue`, `ClientDeliverablesTable.vue`, `ProceedingDetailPage.vue`.

Commit: `57cbd7e58800486133072cd57f4ada54c2f4ef8f` — subject
`PRDV-16047: Gate withdraw approval by withdraw permission`. Pushed to `origin/PRDV-16047`;
opened [atlas-front-end#530](https://github.com/planetdepos/atlas-front-end/pull/530) (reviewer
`daedalus1215`).

#### Shipping checklist

| Gate | Command | Scope | Result |
| ---- | ------- | ----- | ------ |
| audit | `npm audit --audit-level=high` | atlas-front-end | pass — 0 vulnerabilities |
| lint | `npm run lint` | atlas-front-end | pass — 0 warnings (after `npm run lint:fix`) |
| type-check | `npm run type-check` (`vue-tsc --noEmit`) | atlas-front-end | pass — 0 errors |
| tests | `npx vitest run --maxWorkers 1 <ProceedingDetailPage + auth/permissions>` | 14 files | pass — 146 |

- **Tests added/updated:** `__specs__/useProceedingFilePermission.spec.ts` (5 — incl. the
  submission-only drift scenario returning `false`, and multi-track all-or-nothing);
  `__specs__/ProceedingFileRowActionsMenu.spec.ts` (7 — hide-on-no-permission and audio-preserved,
  single + batch, both variants); updated `SubmissionFilesTable.spec.ts` `usePermissions` mock.
- **Regression:** ran the full ProceedingDetailPage component + permissions suites (146 tests) —
  green; Approve / download / rename / delete gating untouched. Table/FAB wiring is straight
  pass-through of the capability, covered indirectly by the menu spec + the exposed `canWithdraw`
  mirroring the existing `canApprove`.
- **API docs:** not relevant — frontend-only; consumes the existing `Permission[]` DTO and the
  existing unapprove endpoint; no HTTP contract change.

### 2026-07-02T03:34:16Z — atlas-front-end / dustin-thomason (planning + investigation)

- Onboarded to PRDV-16047; created branch `PRDV-16047` off updated `main`.
- Ran a read-only investigation across `atlas-front-end` and `callisto-back-end` and **proved** the
  root cause: the "Withdraw approval" menu items are gated on the shared
  `permissions.canModifyDeliverableApproval` flag; the **Submission Files** table computes it on the
  `SUBMISSION_PROCEEDING_FILES_<TRACK>` resource (`isDeliverable=false`), but the backend
  (`MultiDeliverableFileAuthorizeRole`) authorizes withdraw on
  `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>` (`create`, all-tracks-required). Result: over-permission
  → BE 403. The FAB "Withdraw approval for all selected" has **no** permission check. Verified there
  are **exactly three** withdraw entry points and no hidden surfaces; audio has no client-deliverable
  resource key.
- Captured the investigation + a falsifiable verification plan + results (all hypotheses confirmed)
  in `docs/atlas/16047/PRDV-16047-code-investigation.md`.
- Locked decisions (grill-me): **hide** on lack of permission; gate **all three** entry points via a
  **centralized `canWithdrawApproval`** capability (mirrors the single backend authorize-role);
  **preserve** the audio disabled+tooltip (do not adjust intentional design); leave Approve gating
  unchanged; deliverable = a larry-adams-format **story spec** for Larry's review.
- Authored the canonical story spec directly in **larry-adams** (this repo is the team's PR-reviewed
  wiki — confirmed via prior merged spec PRs, e.g. `a9bb697 PRDV-15591 (#6)`, and Dustin's own
  `PRDV-15619` spec commits there), matching **Larry's own bug-fix template**
  (`PRDV-16144-users-not-able-to-add-permissions-for-cud.md`) rather than the heavier feature-spec
  shape: `systems/neptune/permissions/PRDV-16047-gate-unauthorized-withdraw-approval.md`. Wired into
  the Obsidian index (`systems/README.md`). Retired the earlier duplicate draft that had been placed
  in this repo, so the wiki spec is the single source of truth (this changelog links to it, per
  convention, rather than duplicating content).
- Created branch `PRDV-16047` in `larry-adams` off updated `main`, committed
  (`8df4b090ac20eca961ba5ad04aef2efaf1560f80`), pushed, and opened
  [PR #13](https://github.com/planetdepos/larry-adams/pull/13) with `daedalus1215` (Larry Adams,
  confirmed via file-history authorship) requested as reviewer.
- **Prep-only pass in atlas-front-end:** branch created, no product code, no test files, no commits/
  pushes there. The spec PR is in **larry-adams**, per the user's explicit request this session.

**Shipping checklist:** not applicable this pass — planning/spec only; no `atlas-front-end` code or
behavior changed. Implementation, tests (`npm run lint`, `npx vitest run --maxWorkers 1`), and the
full checklist come in the implementation pass after spec review/approval on PR #13.