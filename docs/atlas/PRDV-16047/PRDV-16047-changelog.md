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

**As of 2026-07-07** (verified live via `gh pr view` / `git fetch` — not from memory):

- **Spec PR #13 (larry-adams) — APPROVED.** `daedalus1215` (Larry) approved with comment "lgtm" on
  2026-07-02T19:33:23Z. **Not yet merged** (`mergedAt: null`), but `mergeStateStatus: CLEAN` /
  `mergeable: MERGEABLE` — nothing blocking a merge.
- **Implementation PR #530 (atlas-front-end) — CHANGES REQUESTED, unaddressed.** `derrickdso`
  (Derrick Dieso) requested changes on 2026-07-02T19:34:45Z. The **only** concrete ask (inline
  comment on `useProceedingFilePermission.ts:59`): *"lets clear out these unnecessary comments and
  likely good to go!"* — referring to the explanatory comment block above `canWithdrawApproval`
  (consistent with this repo's "no comments unless the WHY is non-obvious" convention). Reads as
  near-approval once addressed. **`daedalus1215` (Larry) is still the requested reviewer on #530
  but has not yet reviewed the code** (only the spec, PR #13).
- **Branch drift — resolved locally 2026-07-07.** Derrick had pushed a
  `Merge branch 'main' into PRDV-16047` commit (`bdd3fa9d`, 2026-07-02T19:36:10Z, pulling in
  unrelated `main` history — PR #528 / PRDV-9756) directly to `origin/PRDV-16047`. Local checkout was
  5 commits behind; fast-forward `git pull` applied cleanly (no conflicts). Local `atlas-front-end`
  now matches `origin/PRDV-16047` exactly (`bdd3fa9d`).
- **Root cause proven** (read-only investigation, atlas-front-end + callisto-back-end) — captured in
  `docs/atlas/16047/PRDV-16047-code-investigation.md`. Unaffected by the above; still accurate.
- **Implementation** (commit `57cbd7e58800486133072cd57f4ada54c2f4ef8f`): centralized
  `canWithdrawApproval` capability gating all three withdraw entry points; hide-on-no-permission;
  audio disabled+tooltip preserved; Approve untouched.
- **Gates re-verified against the current branch tip (`bdd3fa9d`) on 2026-07-07:**
  `npx vitest run --maxWorkers 1` over `ProceedingDetailPage` + `auth/composables/permissions` →
  **153 passing** (was 146 at original push; +7 from unrelated merged-in media-duration specs). No
  conflicts between this change and what Derrick's merge brought in.
- **Outstanding before merge:** (1) remove the flagged comment block, (2) get Larry's review on #530
  itself (only the spec is reviewed so far), (3) manual UI repro/screenshots per STR, (4) merge #13
  (spec) — approved, unmerged.

## Local testability (verified 2026-07-07 — this was the specific objective of this handoff)

**Answer: the frontend half is confirmed runnable locally; a full end-to-end repro of the ticket's
STR requires a local backend + real dev credentials that this session could not complete.** Details:

### What "local" means for this app

`atlas-front-end` is a Vue/Quasar SPA with **no offline/mocked mode** for auth or permissions.
`.env.local` on this machine sets `ENV_NAME=local` and `CALLISTO_API_URL=http://localhost:3004` —
i.e. the intended local setup is: Atlas frontend dev server (Vite, port 9000) + a **locally-run
`callisto-back-end`** (NestJS, expected on port 3004) + **real AWS Cognito** (dev user pool
`us-east-1_SlOE1Mh9Q`) for login. There is no way to exercise the permission-gated withdraw UI
without a live backend supplying real `Permission[]` data — this is exactly why the ticket's own
STR requires assigning a real role to a real test account.

### Confirmed this session

- Pulled `atlas-front-end` to the exact PR tip (`bdd3fa9d`) — see Branch drift above.
- Started `npm run dev:local` — Quasar/Vite compiled with **no build errors** (only two pre-existing,
  unrelated warnings: `defineEmits`/`defineProps` compiler-macro notices, and a stale
  browserslist-db cache notice). Server bound to `http://localhost:9000`.
- `curl http://localhost:9000` → **HTTP 200**, valid Atlas SPA shell HTML (correct `<title>Atlas`,
  Vite client script, full head/meta) — confirms the app boots and serves on this branch.
- Cleanly stopped the dev server afterward (killed the exact `npm` / `cross-env` / `quasar` PIDs;
  confirmed port 9000 no longer responds).
- **Not attempted:** logging in (no real dev Cognito test credentials available in this session) or
  reaching the Proceeding Detail page — both require a human or an agent with actual credentials.
- **No browser-automation tool** (Playwright/chromium-cli) was available in this environment, so the
  rendered page was not screenshotted — confirmation rests on the HTTP 200 + correct HTML + clean
  compile log, not a visual check.

### A real blocker found — port mismatch

`atlas-front-end/.env.local` expects Callisto at **`localhost:3004`**, but
`callisto-back-end/.env.local` on this machine currently has **`APP_PORT=3003`**
(`callisto-back-end/.env.sample` defaults to `3004`, so `.env.local` there has drifted from sample).
**Whoever runs the full local stack needs to align these** (either set `callisto-back-end`'s
`APP_PORT=3004`, or change Atlas's `CALLISTO_API_URL` to `3003`) before the frontend can reach a
local backend at all.

### `callisto-back-end` was deliberately not touched

It is currently on branch **`PRDV-15776`** (not `main`) with **uncommitted changes**
(`.swcrc`, `notification-template-preview.html` modified; untracked `scripts/`) — this is the user's
own in-progress, unrelated work. This session did not start, stash, or switch that repo. Whoever
picks up local E2E testing needs to decide how to handle that branch (e.g. a separate worktree, or
stash+switch with the owner's awareness) before running the backend locally.

### What's still needed for a full local repro of the STR

1. Resolve the port mismatch above.
2. A `callisto-back-end` instance running locally (`main`, or whatever branch has this ticket's
   assumptions about permissions unchanged) with a seeded local DB.
3. A real dev-environment Cognito account, assigned **only** `Neptune_Facilities` (or another
   partial-permission role) — role membership normally comes from Entra ID group sync; for local
   testing this likely means a seeded/test row in the local `roles`/`permissions` tables rather than
   a real AD sync.
4. Test data: an **unrestricted proceeding** with **approved** files in every track (Transcript /
   Video / MVC / Audio).
5. With that in place: log in, open the row menu on an approved file in a track the test role lacks
   `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>` `create` for — "Withdraw approval" should be
   **hidden** (non-audio) or **shown-disabled-with-tooltip** (audio); the FAB should be disabled for
   the same selection; a track the role IS authorized for should stay active and succeed.

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