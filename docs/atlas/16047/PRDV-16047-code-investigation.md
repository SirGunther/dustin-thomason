# PRDV-16047 — Code Investigation: why the withdraw option appears without permission

> **Ticket:** [PRDV-16047 — ClickUp](https://app.clickup.com/t/43227262/PRDV-16047)
> **Scope of this note:** a light, code-level root-cause capture (the *why* behind the defect),
> for posterity and review **before** committing to a fix plan. The implementation plan lives
> separately. Frontend repo: `atlas-front-end`. Backend (reference only): `callisto-back-end`.
> **Investigated:** 2026-07-01 (Dustin Thomason).

---

## TL;DR

"Withdraw approval" (un-approve a client deliverable) is gated in the UI by a **single shared
permission flag, `permissions.canModifyDeliverableApproval`**, that each parent table computes with
a **table-wide `isDeliverable` constant**. That constant decides which backend *resource key* the
flag is checked against:

- **Submission Files table** → `isDeliverable = false` → checks `SUBMISSION_PROCEEDING_FILES_<TRACK>`
- **Client Deliverables table** → `isDeliverable = true` → checks `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>`

But the backend authorizes **withdraw** against the **client-deliverable** resource, while it
authorizes **approve** against the **submission** resource. The one shared flag therefore
**conflates two different backend permissions**. In the Submission Files table it is *correct for
Approve but wrong for Withdraw*: a role that holds submission-`create` but not
client-deliverable-`create` (any "partial permissions" role, e.g. `Neptune_Facilities`) gets a
**truthy** flag → the withdraw item is fully active → clicking it fires a request the backend
then rejects (the "click withdraw, get a BE error" symptom).

A second, unrelated gap: the **FAB "Withdraw approval for all selected"** performs **no permission
check at all** — it gates only on approval state.

---

## 1. What "Withdraw approval" is

It is an **un-approve** of a client deliverable, not a file delete. Labels:
`common.callisto.files.withdrawApproval` (single) / `withdrawApprovalForSelected` (batch) /
`common.callisto.fab.withdrawApprovalAll` (FAB). It POSTs to
`…/granting-client-access/unapprove-files-for-delivery`.

## 2. Where it is rendered — one shared component

All per-row menus (single + batch) render through **one** shared component:

- `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/ProceedingFileRowActionsMenu/ProceedingFileRowActionsMenu.vue`
  - Batch "Withdraw approval for selected" item: **lines 159–189**
  - Single "Withdraw approval" item: **lines 311–343**
  - Permissions prop type `ProceedingFileRowMenuPermissions`: **lines 14–19**

Used by exactly two parent tables (same folder):
- `SubmissionFilesTable/SubmissionFilesTable.vue` — passes `variant="submission"`, `:permissions="hasPermissionForSelectedFiles"` (line 840)
- `ClientDeliverablesTable/ClientDeliverablesTable.vue` — passes `variant="clientDeliverable"`, `:permissions="getRowPermissions(file)"` (line 924, per-row) and `:permissions="hasPermissionForSelectedFiles"` (line 1009, multi-select)

Because it is a single shared render path, one correct gate covers all tracks and both categories.

## 3. How the permission is *supposed* to be checked

The relevant system is the **fine-grained permission DTO** (`Permission[]` on
`authStore.authUser.permissions`, loaded from `fetchPermissions()`), not the coarse role-string
`hasPermission(roleBase, access)`.

`src/callisto/auth/composables/permissions/useProceedingFilePermission.ts`:

```ts
singleProceedingFileAuth(trackTypeId, isDeliverable, action)
  → getResourceKey(isDeliverable, trackTypeId) → hasPermission(permissions, resourceKey, action)

getResourceKey(isDeliverable, trackTypeId) =
  (isDeliverable ? 'CLIENT_DELIVERABLE_PROCEEDING_FILES_' : 'SUBMISSION_PROCEEDING_FILES_')
  + FILE_PROCEEDING_TRACK_TYPES[trackTypeId]
```

So **`isDeliverable` alone chooses submission-vs-deliverable resource key.** `hasPermission`
(`src/auth/utils/checkPermissions.ts`) returns true iff a matching `{resourceKey, action}` row
exists with `effect === ALLOW`.

## 4. The defect — resource-key drift

The withdraw items gate on `permissions.canModifyDeliverableApproval`. That value is built here:

- `SubmissionFilesTable.vue`
  - `const isDeliverable = false;` — **line 98**
  - `hasPermissionForSelectedFiles` (lines 213–243): `canModifyDeliverableApproval: multiProceedingFilesAuth(filesToCheck, ACTION_TYPES.CREATE)` where every `filesToCheck` entry carries `isDeliverable: false` (line 220) → resource key `SUBMISSION_PROCEEDING_FILES_<TRACK>`.
- `ClientDeliverablesTable.vue`
  - `const isDeliverable = true;` — **line 182**
  - `getRowPermissions` (lines 629–657) / `hasPermissionForSelectedFiles` (lines 572–602) → resource key `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>`.

Now compare the backend guards (the actual enforcement) in
`callisto-back-end/src/granting-client-access/application/guards/`:

| UI action | Backend guard | Authorize-role | Resource key checked | Action |
|-----------|---------------|----------------|----------------------|--------|
| **Withdraw** (unapprove) | `unapprove-files-for-delivery-auth.guard.ts` | `MultiDeliverableFileAuthorizeRole` | `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>` | `create` |
| **Approve** | `approve-files-for-delivery-auth.guard.ts` | `MultiSubmissionFileAuthorizeRole` | `SUBMISSION_PROCEEDING_FILES_<TRACK>` | `create` |

**The mismatch:** withdraw and approve legitimately use *different* resource keys on the backend,
but the frontend gates both on the one `canModifyDeliverableApproval` flag.

- In the **Client Deliverables** table the flag is computed on the deliverable resource → it
  matches the withdraw guard → withdraw is gated correctly there.
- In the **Submission Files** table the flag is computed on the submission resource. That is
  *correct for the Approve item* (which the submission table also renders) but **wrong for the
  Withdraw item**. A role with `create` on `SUBMISSION_PROCEEDING_FILES_<TRACK>` but not on
  `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>` gets `canModifyDeliverableApproval = true`, so the
  withdraw item is presented as active — and the backend then 403s the actual request.

This is exactly the STR: an **approved submission file** (a submission file that has become a
client deliverable) shown in the Submission Files track, withdrawn by a partial-permission role.

## 5. Why it shows "enabled" rather than greyed

Even where the flag *is* false, the withdraw items only gate **visibility** on approval state and
apply permission as a **CSS class + click guard**, not on the `v-if`:

- `v-if="approvalStatus.canUnapprove"` (batch) / `v-if="canUnapproveSubmissionFile(rowFile)"` (single) — **state only**
- `:class="[{ disabled: !permissions?.canModifyDeliverableApproval || … }]"` and
  `@click="permissions?.canModifyDeliverableApproval && … ? unapprove…() : null"` — permission only affects styling + the click handler.

So in the submission-table path, because the flag is *wrongly true*, neither the `disabled` class
nor the click guard engages → the item is fully clickable → BE error. (In the client-deliverable
path, where the flag is correctly false, the item is at least greyed and non-clicking — but still
visible, which is the softer half of the same ticket.)

## 6. Second gap — the FAB is completely ungated

`ProceedingDetailPage.vue` builds the selection FAB actions; the withdraw action (**lines 437–447**)
is:

```ts
{ key: 'withdraw-approval', label: t('common.callisto.fab.withdrawApprovalAll'),
  disabled: !approvalStatus.canUnapprove,          // line 443 — NO permission check
  handler: () => ref?.handleUnapprove() }
```

`approvalStatus` here is `getSelectedFilesApprovalStatus()` from the active table — purely file
state. So a user without withdraw permission can trigger the same rejected request from the FAB,
independent of the row menu.

## 7. Why it presents as "any role with partial permissions," across "all tracks"

`multiProceedingFilesAuth` (useProceedingFilePermission.ts lines 20–40) requires **every distinct
selected track** to have an ALLOW row (`Array.from(resourceKeys).every(...)`), mirroring the
backend's all-or-nothing check. A partial-permission role passes on the tracks it owns and fails
on the others — so the withdraw option appears across tracks but only *fails* on the unauthorized
ones. This matches Anastasiya's refinement note: "it started for one role and then I realized it
might happen for any role that has partial permissions," and "this seems like only front end."

Note also: there is **no** `CLIENT_DELIVERABLE_PROCEEDING_FILES_DIGITAL` (audio) resource key; the
UI already special-cases audio as non-withdrawable, so audio is not part of this defect.

## 8. Evidence map (file : line)

| What | Location |
|------|----------|
| Shared menu, batch withdraw item | `ProceedingFileRowActionsMenu.vue:159-189` |
| Shared menu, single withdraw item | `ProceedingFileRowActionsMenu.vue:311-343` |
| Submission table `isDeliverable = false` | `SubmissionFilesTable.vue:98` |
| Submission table flag build | `SubmissionFilesTable.vue:213-243` (esp. 220, 226) |
| Client-deliverable table `isDeliverable = true` | `ClientDeliverablesTable.vue:182` |
| Client-deliverable per-row / multi flag build | `ClientDeliverablesTable.vue:572-602, 629-657` |
| Resource-key mapping | `useProceedingFilePermission.ts:11-53` |
| Permission check primitive | `src/auth/utils/checkPermissions.ts` (`hasPermission`) |
| Track id → name (no deliverable audio key) | `src/auth/utils/permissions.ts` (`FILE_PROCEEDING_TRACK_TYPES`, `RESOURCE_KEY_TYPES`) |
| FAB withdraw action (ungated) | `ProceedingDetailPage.vue:437-447` (443) |
| Backend withdraw guard | `callisto-back-end/.../guards/unapprove-files-for-delivery-auth.guard.ts` (`MultiDeliverableFileAuthorizeRole`, `CREATE`) |
| Backend approve guard | `callisto-back-end/.../guards/approve-files-for-delivery-auth.guard.ts` (`MultiSubmissionFileAuthorizeRole`, `CREATE`) |

## 9. Conclusion (what the fix must address)

1. Withdraw must be gated on the **client-deliverable** resource key regardless of which table
   renders it — i.e. it cannot keep sharing `canModifyDeliverableApproval` with Approve in the
   Submission Files table.
2. All **three** entry points consume that gate: single row item, batch row item, and the FAB
   (which today has no permission check at all).
3. The gate must be **dynamic** (resource/action/effect via `useProceedingFilePermission`), not
   keyed on role IDs.

Authoritative source of truth used here = the **backend guards** (read directly). The linked
ClickUp permissions sheet is the product reference; confirm access, but the guards are the
enforcement the UI must mirror.

---

## 10. Verification plan — proving the assumptions

Guiding principle: the fix must be **no simpler than it needs to be, and no more complex than it
needs to be.** Each claim below is written so it can be **refuted**; the next section records
confirm/revise with evidence. We test the happy path *and* build negative/inferred paths (prove the
defect isn't leaking in from — or out to — somewhere we haven't modelled).

### Falsifiable hypotheses

| # | Hypothesis | How to prove / refute | Refuted if… |
|---|-----------|------------------------|-------------|
| H1 | Backend **withdraw** authorizes `create` on `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>`, all-tracks-required | Read `MultiDeliverableFileAuthorizeRole` impl (not just the guard) | it uses submission keys, a different action, or any-track-passes |
| H2 | Backend **approve** authorizes `create` on `SUBMISSION_PROCEEDING_FILES_<TRACK>` | Read `MultiSubmissionFileAuthorizeRole` impl | it uses deliverable keys |
| H3 | FE **Submission** table gates withdraw on the **submission** resource (the drift) | Trace menu prop chain → `isDeliverable=false` → `getResourceKey` | it already computes a deliverable-scoped flag for withdraw |
| H4 | The single `canModifyDeliverableApproval` flag is shared by **approve AND withdraw** (so flipping it wholesale is wrong) | Confirm both menu items reference the same flag | they already use separate flags |
| H5 | FE ↔ BE resource-key strings match exactly (casing; `DIGITAL` audio) | Diff FE `RESOURCE_KEY_TYPES` vs BE `RESOURCE_KEY_TYPES` + track maps | mismatched → that would be a *different* bug |
| H6 | We have found **all** withdraw entry points (row single, row batch, FAB) | Enumerate every caller of the unapprove flow (`startUnapproveFlow`, `handleUnapprove*`, `unapproveFilesForDelivery`, `useUnapproveFiles`) + every "withdraw" i18n usage, incl. the deliverables **bulk-action bar** (`…bulkActions.withdrawApprovalAll`) and any deliverables page/collection surface | there are more surfaces → scope expands |
| H7 | Not a stale/empty-selection artifact (`multiProceedingFilesAuth([])` is vacuously `true`) | Confirm both tables early-return on empty selection and set selection to the row on menu-open | any path passes an empty file list to the auth check |
| H8 | The **Client Deliverables** table path is already correctly gated (no "enabled+error" there) | Confirm CD per-row + multi use the deliverable resource | CD also over-permits |

### Class / architecture / scale questions (must answer, not just the instance)

- **Solves the class?** The class is "UI offers a permission-gated action the backend rejects." Does
  gating *every* withdraw surface on one correct deliverable-scoped capability close it for
  withdraw, and is that capability reusable so future withdraw surfaces are correct by construction?
  Sibling instances (upload-on-restricted, PRDV-16185) are separate tickets — confirm out of scope
  and not regressed by this change.
- **Best practices / architecture fit?** The established pattern is "parent computes a `permissions`
  object via `usePermissions()` and passes it to the shared menu." Verify the menu lacks the batch
  selection context needed to compute this itself (which would make an in-menu computation both more
  complex and wrong), confirming parent-computes is the correct, minimal seam.
- **Scale?** New tracks / resource keys must flow through `getResourceKey` + `FILE_PROCEEDING_TRACK_TYPES`
  with **no** per-track hardcoding; batch must dedupe by resource key. Verify the fix adds no
  track-specific branches.

## 11. Verification results — all hypotheses tested (read-only)

| # | Verdict | Evidence |
|---|---------|----------|
| H1 | **Confirmed** | `MultiDeliverableFileAuthorizeRole.apply()` builds `'CLIENT_DELIVERABLE_PROCEEDING_FILES_' + FILE_PROCEEDING_TRACK_TYPES[trackTypeId]`, requires action `create`, and is all-tracks-required (`return resourceKeys.size === matchedCount`). Guard passes `ACTIONS_TYPES.CREATE`. |
| H2 | **Confirmed** | `MultiSubmissionFileAuthorizeRole.apply()` builds `'SUBMISSION_PROCEEDING_FILES_' + <track>`, `create`, identical all-or-nothing logic. |
| H3 | **Confirmed** | `SubmissionFilesTable.vue:98` `isDeliverable = false` → `hasPermissionForSelectedFiles` (L213-243) computes the flag on the submission resource; row menu receives it via `:permissions` (L840); `:open-menu="(id) => selectedFiles.add(id)"` (L839) adds the row to the selection (note: does **not** clear first, unlike CD's `openRowActionsMenu`). |
| H4 | **Confirmed** | In the shared menu, the Approve items and the Withdraw items **both** gate on `permissions.canModifyDeliverableApproval` — one flag serving two backend-distinct actions. Flipping it wholesale would misgate Approve. |
| H5 | **Confirmed** | FE `getResourceKey` + `FILE_PROCEEDING_TRACK_TYPES` (`1 EXHIBITS, 2 TRANSCRIPT, 3 VIDEO, 4 MVC, 5 DIGITAL`) produce **byte-identical** keys to the backend; both sides match on positive `effect === ALLOW` only (no deny-override). |
| H6 | **Confirmed** | Exactly **three** UI entry points (row single `…RowActionsMenu.vue:311-343`, row batch `:159-189`, FAB `ProceedingDetailPage.vue:437-447`). Single-entry plumbing: `useUnapproveFlow` imported only by the two tables. The feared `common.callisto.case.deliverables.bulkActions.withdrawApprovalAll` key **does not exist**; no deliverables/collections/AJSF withdraw surface. |
| H7 | **Confirmed** | Not an empty-selection artifact: both tables early-return `undefined` at size 0; `filesToCheck` is never empty when size>0; an unmatched track → key `…_undefined` → no ALLOW → `false` (not vacuously `true`). |
| H8 | **Confirmed** | CD table computes on the deliverable resource (per-row `getRowPermissions` `isDeliverable=true`; multi uses `isClientDeliverable(file)`) — already correctly gated. |

### Root cause — proven, single and specific
The withdraw items are gated by the shared `canModifyDeliverableApproval` flag. In the **Submission
Files** table that flag is computed on the **submission** resource (`isDeliverable=false`), but the
backend authorizes withdraw on the **client-deliverable** resource. A partial-permission role with
submission-`create` but not deliverable-`create` gets a truthy flag → the withdraw item is active →
the click is rejected by the backend (403). The **FAB** has no permission check at all. Everything
else (client-deliverable table path, empty-selection handling, resource-key strings) is correct.

### Newly surfaced nuance — audio / DIGITAL (decision needed)
There is **no** `CLIENT_DELIVERABLE_PROCEEDING_FILES_DIGITAL` (audio) resource key on the backend, so
a deliverable-scoped withdraw permission is **always `false` for audio**. If the withdraw item's
`v-if` is gated on that permission, the audio withdraw item — today shown **disabled with a "cannot
withdraw audio files" tooltip** (submission variant, `RowActionsMenu.vue:311-343, 338-342`) — would
instead become **hidden**. Two clean options:
- **(A) Accept hiding audio too** — simplest, one uniform "hide when unavailable" rule; loses the
  audio-specific tooltip.
- **(B) Preserve audio's disabled+tooltip** — apply the permission-hide only for the non-audio
  reason; keep the existing explicit audio branch. Slightly more conditional logic, zero behavior
  change for audio.

**Resolved → (B).** The audio disabled+tooltip is an intentional UX feature; a defect fix should not
remove intentional design. Withdraw `v-if` = `<state> && (audioSpecialCase || canWithdrawApproval)`.
The audio approve-but-never-withdraw asymmetry (missing `CLIENT_DELIVERABLE_PROCEEDING_FILES_DIGITAL`
key) is **surfaced to Larry as an open question**, not changed by this ticket.

### Class / architecture / scale (answered)
- **Class:** the class is "UI offers a permission-gated action the backend rejects." For withdraw
  there are exactly three surfaces; gating all three on **one** deliverable-scoped capability closes
  it. Centralizing that rule (a single `canWithdrawApproval(files)` helper mirroring the one backend
  `MultiDeliverableFileAuthorizeRole`) makes future withdraw surfaces correct by construction. The
  sibling instance PRDV-16185 (upload button on restricted cases) is the same class but a **separate
  ticket** — out of scope, and untouched by this change.
- **Architecture fit:** the shared menu only receives `rowFile` + audio/selection flags, **not** the
  batch selection's track set, so it cannot compute the batch capability itself — confirming the
  established "parent computes a `permissions` object via `usePermissions()` → passes to the menu"
  seam is the correct, minimal place. The FAB reads the active table's exposed API, so the capability
  is exposed there. No new API, no role IDs.
- **Scale:** the capability flows through `getResourceKey` + `FILE_PROCEEDING_TRACK_TYPES` (no
  per-track hardcoding); `multiProceedingFilesAuth` dedupes by resource key (`Set`) → O(distinct
  tracks); audio is auto-forbidden via the missing key. Adding a future track needs no change here.

### Bounded fix (no simpler, no more complex than needed)
1. Add one semantic capability to `useProceedingFilePermission`:
   `canWithdrawApproval(files) = multiProceedingFilesAuth(files.map(f => ({ ...f, isDeliverable: true })), ACTION_TYPES.CREATE)`
   — names the withdraw rule once, deliverable-scoped, mirroring the single backend authorize-role.
2. Consume it in all three surfaces: the two menu withdraw items' `v-if` (hide), both tables'
   `permissions` object + `defineExpose`, and the FAB action's `disabled`.
3. Leave Approve on the submission-scoped `canModifyDeliverableApproval` (unchanged — proven correct).
