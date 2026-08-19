# Coverage ledger — atlas/PRDV-16403

Investigation question: can the four RB-sourced values (case / contact / firm warnings, case remarks HTML) be read from Callisto and rendered read-only in the existing Access Manager panel, and what does the current code make hard or impossible?

Repo(s): `callisto-back-end`, `atlas-front-end`, `larry-adams` (read-only) · Baseline commits: `atlas-front-end` `main` **`02c98e1e`**; `callisto-back-end` `PRDV-16313` **`c43be32c`** with `origin/main` at **`631ed42e`** · Started: 2026-08-18

## Consulted

- `docs/atlas/*/investigations/*-coverage-ledger.md` for "granting-client-access", "contacts", "firms", "cases", "read endpoint", "AccessManager", "src/callisto", "dompurify", "sanitize", "v-html", "XSS", "feature flag" — **five ledgers found, all five read.**
- **PRDV-16312** — found + reused for GCA module / registry / architecture / transaction / spec-convention ground (its areas 1-7, 10). Its area 9 (dependency state) **not reopened** — already corrected as stale by PRDV-16313. Its `IS_GRANTING_CLIENT_ACCESS_ENABLED` manual-test blocker **reopened under condition 2 (state changed)** → became area 7 below.
- **PRDV-16313** — found + heavily reused for GCA action / service / guard shape, the architecture fitness rules, module dependency direction, `AuthUser` conventions and spec conventions (its areas 1, 4-7, 9-11). Its claim *"no feature flags in `granting-client-access`"* **reopened under condition 1 (new evidence contradicts) and corrected** — `IS_CLIENT_ACCESS_OUTBOX_ENABLED` shipped via PRDV-16310, resolved in `ContactsService`.
- **PRDV-16402** — found + reused for `atlas-front-end/src/callisto/api/constants.ts`, the Vue Query `staleTime` convention, repository-naming precedents and the backend flag-resolution pattern (its areas 6-8, 16-18).
- **PRDV-14055** — found + reused narrowly for the shared `common.json` i18n namespace (the same file this ticket extends) and Atlas `__specs__` conventions. Its baseline `ef217844` is ~13 months stale; nothing was leaned on without re-verification.
- **PRDV-16192** — found, **not reopened**. Different subsystem (Europa / `src/europa/`). Only the *projection → DTO → responder* triad transfers as a pattern.
- **`docs/atlas/reviews/`** — **not ledger-formatted, so the ledger glob misses it entirely.** Searched separately and found to be the **only** prior coverage of `granting-client-access/contacts/` anywhere: the PRDV-16310 / 16315 PR reviews. Reused for the write-side call graph, the feature-flag precedent, type-placement rules, and the whole-module test-gate baseline (`npx jest --config jest-e2e.json --runInBand src/granting-client-access` → 75 suites, 361 tests, pass). **Recommendation: add this folder to the consult glob permanently.**
- **No frontier item in any ledger is this ticket.** Two merely touch it: PRDV-16313's *"other five unbuilt epic events"* (same module, scope boundary) and its *"`trackTypeId` guard mismatch"* — the latter does **not** apply, because the guard precedent here is the read-side `ProceedingsReadAuthGuard`, not `UpdateDeliverableFileAuthGuard`.
- **Virgin ground, established by grep across all of `docs/`:** no prior ticket investigated a GCA **read** endpoint, the `contacts`/`firms`/`cases` entity columns, the `AccessManagerOverlay` tree, or HTML sanitization / DOMPurify / `v-html` / XSS as a behaviour. The only sanitization hits anywhere are two npm-audit dependency mentions (PRDV-15619, PRDV-16150).
- `dnu/` folders excluded throughout, including `docs/atlas/PRDV-16312/dnu`.

## Areas examined

### 1. `atlas-front-end` — `AccessManagerOverlay.vue` and its SCSS module (the panel to fill)

| Field | Value |
| --- | --- |
| Inspected | Whole component (376 lines): props block, `useAccessManager` call, `<Overlay>` bindings, left-column loading/error markup, `section.rightColumn` and its `<header>`. Whole SCSS module (248 lines): `.rightColumn`, `.rightHeader`, `.rightColumnHeader`, `.rbPlaceholder`, `.dynamicEmptyState`, and the `:global(.access-manager-overlay__content)` height chain |
| Findings | `data-testid="rb-warnings-panel"` already sits on the `<section>` (L318), not on any child. The placeholder `<p>` to replace is L333-335; `warningsTitle` and the overlay close button live in a **sibling `<header>` at L319-332**, outside it. Props include `proceedingId: number` and `contact` (L24-32); `contactId` computed L41. `<Overlay :loading="isLoading">` at L151 is fed **only** by `useAccessManager`. Left column renders `q-banner` for error and `q-spinner` inside `.statusMessage` for loading, error taking precedence via `v-else-if`. **`.rightColumn` is `overflow: hidden`** — it clips, it does not scroll; `.leftColumn` has `overflow-y: auto` |
| Status | fully-inspected |
| Commit | `02c98e1e` · 2026-08-18 |
| Evidence | `AccessManagerOverlay.vue:24-32,41,151,179-189,318-337`; `AccessManagerOverlay.module.scss` `.rightColumn` / `.rightHeader` / `.rbPlaceholder` / L116-127 / L241-247 |
| Notes | Source of **F6**. The empty-state precedent in this very module is `rgba($schemes-on-surface, 0.38)`, not 50% and not italic |

### 2. `atlas-front-end` — the Access Manager's open/close lifecycle and entry points (surface enumeration)

| Field | Value |
| --- | --- |
| Inspected | `ProceedingDetailPage.vue` L95-132 and L738-756; grep of `isAccessManagerOpen\|accessManagerOpen\|showAccessManager\|openAccessManager` across `src/`; `ContactSearchItem` and `ClientAccessContact` / `ClientAccessFirm` type definitions |
| Findings | **Exactly two entry points:** `handleAddContactFromSearch` (L103, real `ContactSearchItem`) and `handleEditAccessFromList` (L114, **fabricates** a `ContactSearchItem` from a `ClientAccessContact`). The overlay renders under `v-if="isGcaEnabled && accessManagerContact"` (L755) and `handleAccessManagerAfterLeave` (L123-126) nulls both contact and firm name — so **the overlay unmounts on close and remounts on open**. **Neither FE type carries a firm id**: `ContactSearchItem` has `firmName: string \| null` only; `ClientAccessFirm` has `name`, `streetAddress`, `city`, `state` |
| Status | fully-inspected — the entry-point list is complete |
| Commit | `02c98e1e` · 2026-08-18 |
| Evidence | `ProceedingDetailPage.vue:95-132,738-756`; `src/callisto/types/contact-search.ts:1-6`; `src/callisto/types/client-access-list.ts:1-14`. Completeness: `isAccessManagerOpen` declared L101, set `true` at exactly L106 and L117; grep returns only this one file |
| Notes | Source of **F2** (the remount that satisfies freshness) and **F3** (firm resolved two ways). Proves alternative "resolve on the FE" structurally impossible |

### 3. `atlas-front-end` — Vue Query conventions in and around the overlay

| Field | Value |
| --- | --- |
| Inspected | `useAccessManager.ts` in full — params type, both option objects, `isLoading`/`error` aggregation, return type; `useAccessManagerDynamicCollections.ts`; repo-wide grep for `staleTime`, `gcTime`, `refetchOnMount`; `useFeatureFlags.ts`; `contactDeliverableTypeGrants.ts`; `constants.ts:160-178`; `queryKey.ts` |
| Findings | Params are `MaybeRefOrGetter<T>` read through `toValue`. `useAccessManager`'s query has **no `staleTime`, no `gcTime`, no `refetchOnMount`**. `staleTime: TWO_MINUTES` is the house default (5+ call sites). `refetchOnMount: 'always'` exists in exactly two places (`useJobRestrictionLevel`, `useCaseRestrictionLevel`). **`gcTime` appears nowhere in the repo.** `error` is always narrowed `instanceof Error` to `Error \| null`. URL builders are `FETCH_*_URL`; `queryKey.ts` holds 12 keys, none for warnings |
| Status | fully-inspected |
| Commit | `02c98e1e` · 2026-08-18 |
| Evidence | `composables/useAccessManager.ts` (whole); `constants.ts:164-169`; `queryKey.ts:1-14`; `useFeatureFlags.ts:12-20` |
| Notes | Confirms **F2**: of the three cache options the ticket prescribes, only `gcTime: 0` does work, and it is the one with zero precedent |

### 4. `atlas-front-end` — the sanitisation precedent

| Field | Value |
| --- | --- |
| Inspected | `NotificationBody.vue` in full (85 lines); repo-wide grep for `DOMPurify`, `v-html`, `innerHTML`; `package.json` dependency line; `eslint.config.mjs`; `.cursor/rules/planetdepos-quasar.mdc` |
| Findings | **Exactly one** `v-html` and **one** `DOMPurify.sanitize` in all of `src/`, and it passes **no config object**. Suppression is a paired inline `<!-- eslint-disable vue/no-v-html -->` block, not a config override; the rule is a warning inherited from `flat/recommended`. `dompurify ^3.2.6` declared, **3.4.11 resolved** in the lockfile. `.cursor/rules/planetdepos-quasar.mdc` L214 instructs *"Avoid `v-html` when possible"* |
| Status | fully-inspected |
| Commit | `02c98e1e` · 2026-08-18 |
| Evidence | `NotificationBody.vue:6,32-35,41-43`; `package.json:44`; `planetdepos-quasar.mdc:214` |
| Notes | Source of **F4**. This file has **never been investigated by any prior ticket** — see Consulted. Bare `sanitize()` already strips every construct the AC names forbidden, which is what makes D6 a real question |

### 5. `callisto-back-end` — the read-stack siblings to mirror

| Field | Value |
| --- | --- |
| Inspected | `contacts.controller.ts`; `fetch-contact-deliverable-type-grants.action.ts`, its response DTO, swagger helper, TS folder (`.transaction.script.ts` + `.param.ts`) and projection; `fetch-client-access-list-action/` all four files; `client-access-list.repository.ts` in full; `contacts.service.ts` in full; `validate-contact-exists.validator.ts`; `validate-proceeding-exists.validator.ts`; all three GCA registries; `granting-client-access.module.ts`; `job.module.ts`, `proceedings.module.ts`, `cases.module.ts` export lists |
| Findings | Routes are declared on the **action** via `@ContactsController()` + `@Get(...)`, not on the controller. **The grants action the ticket names to mirror has no mapper, no `@UseGuards`, and the loose `ParseIntPipe`;** `FetchClientAccessListAction` has a nested nullable-object DTO, an application-layer mapper, `@UseGuards(ProceedingsReadAuthGuard)` and `new ParseIntPipe({ errorHttpStatusCode: 400 })`. **`ValidateContactExists` throws `BadRequestException` (400), not 404.** `ClientAccessListRepository` injects one root repository and passes joined **entity classes** to `.leftJoin(Firm, 'firm', 'firm.id = contact.account_id')`, selecting double-quoted camelCase aliases into `.getRawMany<T>()`. `forFeature` holds Contact + Firm but **not** Case/Job/Proceeding, and **none of `JobModule` / `ProceedingsModule` / `CaseModule` re-exports `TypeOrmModule`** |
| Status | fully-inspected |
| Commit | `c43be32c` (local) with `origin/main` `631ed42e` cross-checks · 2026-08-18 |
| Evidence | `granting-client-access.module.ts:52-64,65-71`; `registries/action.registry.ts:12,31`; `repository.registry.ts:10-12`; `validate-contact-exists.validator.ts` (whole); `client-access-list.repository.ts` (whole) |
| Notes | Source of **F7** and **F8** |

### 6. `callisto-back-end` — the RB9 data contract and PRDV-16391's actual state

| Field | Value |
| --- | --- |
| Inspected | `contact.entity.ts`, `firm.entity.ts`, `case.entity.ts` (local **and** `origin/main`), `job.entity.ts`, `proceeding.entity.ts`; `git merge-base --is-ancestor 53d961ed origin/main`; migration `1786036989067-alter__add_warning_remarks__cases_table.ts`; the PRDV-16391 spec's mapping table; `docs/data/replicated-rb9-data.md`; `larry-adams/data-manual/rb9-replicated-timestamps.md` |
| Findings | **PRDV-16391 is merged** — `53d961ed` is an ancestor of `origin/main`; the migration adds `cases.warning` (varchar NULL), `cases.remarks` (text NULL), `cases.remarks_html` (text NULL); `Case` carries all three at L37-42 on `origin/main` and **none of them on the local branch**. Nullability is **asymmetric**: `contacts.warning` and `firms.warning` are NOT NULL varchar and may be `''`. `contact.account_id` has **no FK**. `job.case_id` is nullable (→ LEFT JOIN); `proceeding.job_id` is not (→ INNER JOIN). All four entities extend `ImportedBaseEntity` — replication writes them, the app never does |
| Status | contributing — **refuted the Phase 0 blocker claim** |
| Commit | `origin/main` `631ed42e`, local `c43be32c` · 2026-08-18 |
| Evidence | `contact.entity.ts:19,52,88`; `firm.entity.ts:51`; `origin/main:src/cases/domain/entities/case.entity.ts:37-42`; `job.entity.ts:31`; `proceeding.entity.ts:25` |
| Notes | Source of **F5** and of the §0 correction. The local-vs-`origin/main` divergence is exactly what produced the wrong Phase 0 claim |

### 7. `callisto-back-end` + `atlas-front-end` — feature-flag resolution (reopened from PRDV-16312)

| Field | Value |
| --- | --- |
| Inspected | `is-feature-allowed.transaction.script.ts` in full; `atlas-front-end/src/callisto/auth/composables/featureFlags/useGrantingClientAccessFlag.ts` and `useFeatureFlags.ts` in full; grep for `DEV_FEATURE_FLAG_OVERRIDES\|FEATURE_FLAG_OVERRIDE` across `atlas-front-end`; PRDV-16312's test plan and PRDV-15776's changelog |
| Findings | **No override mechanism exists on either side.** `IsFeatureAllowedTS` carries an explicit JSDoc: *"Feature access follows Cognito token claims only (`identity.featureFlags`). There is no server-side env override; flags must be assigned in Cognito/Atlas for every environment including local."* Atlas simply fetches the list from Callisto. **PRDV-15776's recorded `CALLISTO_DEV_FEATURE_FLAG_OVERRIDES` workaround does not exist**, so PRDV-16312's blocker — *"Setting it did not survive a re-login … unresolved"* — is still live. The GCA flag gates the overlay at the parent (`v-if`, L755); `AccessManagerOverlay.vue` contains **zero** flag checks |
| Status | contributing — **the reopen was justified and the prior workaround refuted** |
| Commit | `c43be32c` / `02c98e1e` · 2026-08-18 |
| Evidence | `is-feature-allowed.transaction.script.ts` (whole, incl. class JSDoc); `useFeatureFlags.ts:12-20`; grep returns empty |
| Notes | Source of **F9**, the largest risk in the report. Reopened under condition 2 (state changed since PRDV-16312's record) |

### 8. `callisto-back-end` — architecture fitness functions and test harness

| Field | Value |
| --- | --- |
| Inspected | `.cursor/rules/` listing plus `architecture-patterns.mdc` DI matrix and `backend-service-design.mdc`; `fitness-functions-rules/architecture-rules/` — `transaction-scripts.rules.ts`, `repositories.rules.ts`, `services.rules.ts`, `layer-dependencies.rules.ts`, `common.rules.ts`, `cross-module-boundaries/domain-boundaries.rules.ts`; naming/structure checkers; `package.json` scripts; the contacts module's 11 spec files; `src/test-utils/repository-test.helper.ts`; `test-database.module.ts`; the four seeders under `contacts/test-utils/integration-test-helpers/seeds/` |
| Findings | `transaction-scripts-no-other-transaction-scripts`, `repositories-no-mappers`, `services-no-mappers`, `domain-no-application` and `no-orphans` are all **`severity: error`** and run via `pretest`. GET handlers must start with `Fetch`. `granting-client-access` is in `NON_DOMAIN_MODULES`, so importing `case.entity.ts` is allowed. Repository specs are **real-Postgres `*.integration.spec.ts`**, excluded from `npm test` and run by `npm run test:integration`. **`seedContact` and `seedFirm` hardcode `warning` to `''` with no override; `seedProceeding` inserts its `jobs` row with no `case_id`; no `case.test-seeder.ts` exists** |
| Status | fully-inspected — **not executed** |
| Commit | `c43be32c` · 2026-08-18 |
| Evidence | `package.json` `test:architecture` / `test:conventions` / `pretest`; the six rule modules named above; `contacts/test-utils/integration-test-helpers/seeds/{contact,firm,proceeding,deliverable-access-grant}.test-seeder.ts` |
| Notes | **Read, not run** — no gate command was executed this phase, so no pass/fail is claimed anywhere in this investigation. Owes an actual `npm run test:architecture` run at Phase 5 |

## Not yet inspected (frontier)

- ~~The `search-contacts` projection's `firmName` derivation~~ — **CLOSED 2026-08-18 (Phase 3 reconcile).** Traced: `ContactsRepository` uses `leftJoin(Firm, 'firm', 'firm.id = contact.account_id')` selecting `firm.name AS "firmName"` (`contacts.repository.ts:51,56`) — the **same** join as `ClientAccessListRepository`. Both frontend sources of the firm name therefore share the edge the warnings query uses, so **F3** is theoretical rather than live. Concern C1 downgraded accordingly.
- **`NotificationBody.vue` as a behaviour** — inspected as a *precedent* (area 4) but never investigated by any ticket: no coverage of what RB or notification HTML actually contains, or whether the bare sanitize has ever been wrong in production. Relevant if D6 lands on "pass a config".
- **Cognito flag provisioning** — how `custom:feature-flags` is assigned and why PRDV-16312's assignment did not survive re-login. Outside both repos; gates manual verification (**F9**, D7).
- **Real `cases.remarks_html` content** — no sample of live RB remarks HTML was obtained; the user ruled the formatting question out of scope, so this was deliberately not pursued. Would be the only way to falsify assumptions about what the sanitizer actually meets.
- **`ProceedingsReadAuthGuard`'s internals** — named as the precedent for D3 but its authorization logic was not read. Needed only if D3 lands on "yes".
- **The Atlas `docs/specs/` tree** — whether a UI-side spec landing pad exists and its conventions. Deliberately not pursued: Phase 3 material, and the user is resolving the review-surface question.
- **PRDV-16392's scope and timeline** — read only as far as the PRDV-16391 spec describes it. Whether it ships this sprint determines how long **F1**'s false-empty state persists.
