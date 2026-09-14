# Coverage ledger — atlas/PRDV-14184 (PRDV-14184)

Investigation question: Where can an empty Proceeding Name input appear, and what makes it (not) take keyboard focus when it does?
Repo(s): `atlas-front-end`, `callisto-back-end` · Baseline commits: `atlas-front-end@420c395a`, `callisto-back-end@d84a4628` · Started: 2026-09-11

## Consulted

- `docs/*/*/investigations/*-coverage-ledger.md` for "proceeding" — **found 13 prior ledgers; none reusable.** Every atlas ledger touching proceedings covers proceeding *files* / deliverables / audit events (PRDV-16461 deliverable collections, PRDV-16313 file rename + outbox, PRDV-16403 client-access read guards, PRDV-16192 audit converters, PRDV-16402 upload actions). **No prior ledger inspected the proceeding *create* surface, the `q-input` name fields, or `Overlay.vue`.** No reuse available; no reopen condition triggered (this is a **different behavior** than any recorded inspection).
- Same glob for "focus" / "autofocus" — **none found.** No prior investigation in any project has examined focus behavior.
- `larry-adams` for "14184" / proceeding-name focus — **none found.** No coworker spec exists; this ticket's spec will be the artifact under review.
- `atlas-front-end/docs/specs/**` for `*proceeding*` — **none found.**

## Areas examined

### 1. `atlas-front-end` — `NewProceedingsOverlay.vue` (Surface 1, Job Detail page)

| Field | Value |
| --- | --- |
| Inspected | Whole file (206 lines): `proceedings` / `proceedingErrors` state, `addProceeding`, `removeProceeding`, `resetProceedings`, `handleSave`, `handleClose`, `validateProceeding`, the `v-for` block and the `q-input` binding |
| Findings | Name input `:147-159` has **no `ref` and no `autofocus`**; initial row from `ref([''])` `:29`; rows appended by `push('')` `:93-98`; `v-for="index in proceedings.length"` iterates a **number** and keys by positional index `:140-144`; removal `splice`s `:100-105`; reset reassigns arrays only `:107-110`; duplicate check is **case-sensitive** `:65-67` |
| Status | contributing |
| Commit | `420c395a` · 2026-09-11 |
| Evidence | `NewProceedingsOverlay.vue:29-30, 65-67, 93-98, 100-105, 107-110, 140-144, 147-159` |
| Notes | The case-sensitive duplicate check diverges from both the sibling form and the DB constraint — recorded as a concern, out of scope here |

### 2. `atlas-front-end` — `Overlay.vue` + `AddNewProceeding.vue` (the mount chain that decides the approach)

| Field | Value |
| --- | --- |
| Inspected | `Overlay.vue` in full (131 lines) — props, `handleClose`, Esc handling, both `<Transition>` blocks; `AddNewProceeding.vue` in full (60 lines) — the overlay mount site and its trigger |
| Findings | `Overlay` hides content with **`v-show`** (`:80`, `:92`), not `v-if`; it emits `after-leave` but has **no `after-enter`** hook; it has no focus management and no `defineExpose`. `AddNewProceeding.vue:53-57` mounts `NewProceedingsOverlay` **unconditionally** (no `v-if`), toggling only `v-model`. Therefore Surface 1's input mounts once, hidden, at Job Detail page load and never remounts on open — **a declarative `autofocus` cannot satisfy AC-1 there** |
| Status | contributing |
| Commit | `420c395a` · 2026-09-11 |
| Evidence | `Overlay.vue:68-92` (esp. `:80`, `:92`), `:33-37` (emits); `AddNewProceeding.vue:28, 48, 53-57` |
| Notes | This is the load-bearing finding of the whole investigation (report §5) |

### 3. `atlas-front-end` — `AddProceedingForm.vue` (Surface 2, Job Submission)

| Field | Value |
| --- | --- |
| Inspected | Whole file (189 lines): state, `addProceedingField`, `resetProceedingsForm`, `handleSaveProceedings`, `validateProceeding`, the `v-for` and `q-input`, the reveal trigger; plus its mount chain |
| Findings | Name input `:138-151`, **no `ref`/`autofocus`**; initial row `ref([''])` `:26`; append `push('')` `:86-91`; reveal via `showAddForm = true` `:120`; card is **`v-if="showAddForm"`** `:127` so it **does** mount fresh; whole block gated by `v-if="editing"` `:116`; `v-for` also index-keyed `:132-136`; duplicate check is **case-insensitive** `:51-55` and additionally checks `existingProceedings` `:59-64`. Mounted at `FileUploadSectionCore.vue:307-311`, which is rendered from **two** routes |
| Status | contributing |
| Commit | `420c395a` · 2026-09-11 |
| Evidence | `AddProceedingForm.vue:26-27, 51-64, 86-91, 116, 120, 127, 132-151`; `FileUploadSectionCore.vue:307-311`; `PendingFileUploadSection.vue:179`; `SubmittedFileUploadSection.vue:159` |
| Notes | Fails the naive `autofocus` fix **differently** from Surface 1 — here it would actually work, which is what makes the half-fix plausible in review |

### 4. `atlas-front-end` — surface enumeration (completeness claim)

| Field | Value |
| --- | --- |
| Inspected | Grep of the two i18n keys labelling a proceeding-name input (`enterProceedingName`, `enterNewProceedingName`) across all `src/**/*.vue`; corroborating greps for `addProceeding\|newProceeding\|createProceeding\|proceedingName\|proceedings.push`; scan of `src/europa`, `src/triton`, `src/globalPages`, `src/globalComponents`, `src/globalComposables` for proceeding UI |
| Findings | **Exactly two** surfaces render an empty proceeding-name input (areas 1 and 3). All proceeding UI lives under `src/callisto`; outside it, only two permissions **spec** files mention proceedings. Excluded after inspection: `ProceedingViewList.vue` (read-only list), `ProceedingOverview.vue`, `SubmissionFilesTable.vue`, `ClientDeliverablesTable.vue`, `TrackSelectorForm.vue`, `DeliverableFileUploadForm*` — all consume `proceedingName` as a **display** prop only. `FormField.vue` checked as a possible third path: it is job-submission-scoped, display/field-switch only, and never renders a proceeding-name create input |
| Status | fully-inspected |
| Commit | `420c395a` · 2026-09-11 |
| Evidence | 2-hit i18n grep; `FormField.vue:19-32` (no `autofocus` prop, no `defineExpose`) |
| Notes | Re-runnable as the completeness check in report §8 A2 |

### 5. `atlas-front-end` — repo-wide focus idiom sweep

| Field | Value |
| --- | --- |
| Inspected | Greps for `autofocus`, `.focus()`, `v-focus`, `useFocus`, `nextTick`→focus, `document.activeElement`, `@focus`; every `composables/` and `directives/` location; `eslint.config.mjs`; `.cursor/rules/*.mdc`; `docs/`; `git log -i --grep=focus` |
| Findings | **No reusable focus utility exists** — no directive (no `directives/` folder at all), no focus composable, no shared text-input wrapper, no component prop named `autofocus`. Two one-off idioms: the `autofocus` attribute (7 sites, **all inside lazily-mounted `q-dialog`s**, incl. `RenameDialog.vue:80`) and `ref` + `.focus()` deferred with `setTimeout` (`MainLayout/SearchBar.vue:53-63`, `triton/.../SearchBar.vue:68`). Callback-ref-into-a-map precedent for `v-for` rows at `CaseFilesTable.vue:413`, `ClientDeliverablesTable.vue:921-923`, `SubmissionFilesTable.vue:702-704`. **No a11y lint plugin installed**; nothing in rules, docs, or history discusses or forbids `autofocus`. `useActiveElement()` guards suppress magic-key shortcuts while an input is focused |
| Status | fully-inspected |
| Commit | `420c395a` · 2026-09-11 |
| Evidence | The 7 `autofocus` sites; `SearchBar.vue:23,53-63,129`; `DeleteLinkDialog.vue:20,31-34`; `eslint.config.mjs:62-81`; `KeyboardShortcuts.vue:28-33` |
| Notes | Establishes there is nothing to import — the change writes the first event-driven focus code on these surfaces |

### 6. `atlas-front-end` — Quasar `QInput` API

| Field | Value |
| --- | --- |
| Inspected | `node_modules/quasar/dist/types/index.d.ts` for `QInput` props/methods; `package.json` dependency set |
| Findings | Quasar **2.18.6** (`^2.17.0` declared); no other UI library. `QInput` exposes prop `autofocus` ("Focus field on initial component render") and methods `focus()`, `blur()`, `select()`, plus `nativeEl`. A `ref` on `<q-input>` yields the **component instance**, so `.focus()` on it is the supported route (and is what both SearchBars already do) |
| Status | fully-inspected |
| Commit | `420c395a` · 2026-09-11 |
| Evidence | Quasar type defs (`autofocus` prop; `focus`/`blur`/`select`/`nativeEl` members); `package.json:51` |
| Notes | Confirms no native-element access is required |

### 7. `atlas-front-end` — test harness and existing specs

| Field | Value |
| --- | --- |
| Inspected | `NewProceedingsOverlay.spec.ts` in full (307 lines); `test/vitest/setup-file.ts`; `vitest.config.mts`; `package.json` dev deps and scripts; greps for `toHaveFocus` / `activeElement` across all `__specs__`; glob for an `AddProceedingForm` spec |
| Findings | **No spec anywhere in the repo asserts focus** (zero hits). `@testing-library/jest-dom@^6.9.1` is installed but **never imported and not registered** in `setup-file.ts` (which contains only a comment) — so `toHaveFocus()` is unavailable as-is. Vitest 3.2.4 on **happy-dom**; `@vue/test-utils` dominant. `NewProceedingsOverlay.spec.ts` **stubs `q-input`** `:73-86` with a bare div+input that drops `autofocus` and exposes no `focus()`; its assertions are DOM-shape based. **`AddProceedingForm.vue` has no spec file at all.** Existing overlay coverage coincides closely with the neighbor set that must stay green: validation messages, duplicate detection, max-20 cap, row removal + disabled state, save enable/disable, cancel-resets |
| Status | fully-inspected |
| Commit | `420c395a` · 2026-09-11 |
| Evidence | `NewProceedingsOverlay.spec.ts:73-86, 92-306`; `test/vitest/setup-file.ts`; `package.json:10,73` |
| Notes | Drives report §5 detection gap and the §10 assertion-mechanism decision |

### 8. `callisto-back-end` — proceeding create path

| Field | Value |
| --- | --- |
| Inspected | `CreateProceedingsTS.apply` in full; both create request DTOs; `Proceeding` entity columns and unique constraint; glob of `src/**/*create*proceeding*` |
| Findings | Proceeding name is the `value` column — required `varchar`, **no DB default**, unique per job **case-insensitively**. Both endpoints require client-supplied `values: string[]` (`ArrayMaxSize(20)` on the proceedings route); the TS maps them through with **no defaulting branch**. The name is typed in the UI before any request exists, so **no server-side authority governs this behavior** and **no contract, DTO, guard, or Swagger surface changes** |
| Status | **ruled-out** |
| Commit | `d84a4628` · 2026-09-11 |
| Evidence | `create-proceedings.transaction.script.ts:21-56`; `create-proceedings.request.dto.ts:10-20`; `create-job-submission-proceedings.request.dto.ts:4-14`; `proceeding.entity.ts:17,22-23` |
| Notes | Rules the repo named in the ticket's scope out of the change, on evidence rather than assumption |

### 9. `callisto-back-end` — the proceedings uniqueness constraint (incidental finding, verified after a wrong first reading)

| Field | Value |
| --- | --- |
| Inspected | `proceeding.entity.ts` `@Unique` decorator; migration `1766801287907-alter__add_unique_value_job_id__proceedings_table.ts` in full; sibling migration `1758811836915-alter__add_case_insensitive_unique_constraint__records_table.ts` in full; `CreateProceedingsTS` error handling; grep for `LOWER(` over `src/` |
| Findings | The constraint is **named** `UQ_proceeding_value_per_job_case_insensitive` but implemented as `ALTER TABLE … ADD CONSTRAINT … UNIQUE ("value", "job_id")` — **case-sensitive** in Postgres. The `records` table implements genuine case-insensitivity via `CREATE UNIQUE INDEX … (LOWER("value"), "job_id")`, so the correct pattern exists in-repo and predates the proceedings migration. Consequence: the DB permits names differing only by case; the overlay's case-sensitive client check agrees with it, while the job-submission form's case-insensitive check is **stricter than the database** |
| Status | contributing (to the concern record only — **not** to this ticket's change) |
| Commit | `d84a4628` · 2026-09-11 |
| Evidence | `proceeding.entity.ts:17`; `1766801287907-…:13`; `1758811836915-…:16-19`; `NewProceedingsOverlay.vue:65-67`; `AddProceedingForm.vue:51-55` |
| Notes | **Reopened/corrected:** an initial pass asserted the DB constraint was case-insensitive on the strength of its name and concluded the overlay was the surface out of step. Reading the migration refuted that. Recorded because the error is instructive — the constraint name is actively misleading |

## Not yet inspected (frontier)

- **`Overlay.vue` transition timing vs. focus** — whether `nextTick` suffices or the repo's `setTimeout` precedent is required (report §8 A5). Answerable only by browser observation; deliberately deferred to implementation, not guessed.
- **Whether an appended row under an index-keyed `v-for` mounts a fresh `QInput`** (§8 A4) — resolved by reasoning, not observed. Only governs the rejected alternative; not load-bearing.
- **Enter-key behavior on both create surfaces once focus is default** (§8 A7) — neither surface binds `@keydown.enter` today, which points to "safe"; the confirming assertion has not been written.
- **The two surfaces' divergent duplicate-check case sensitivity** — identified and recorded as a concern, but the *user-visible consequence* (an overlay-created name colliding with the DB's case-insensitive constraint) was not traced through to the error the user actually sees.
- **`FileUploadSectionCore`'s two host routes** — the mount sites were confirmed, but neither Pending nor Submitted page was inspected for surrounding focus/scroll behavior that could interact with a newly focused input.
