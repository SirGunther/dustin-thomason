---
ticket: PRDV-16403
addendum-to: callisto-back-end/docs/specs/atlas-client-access/contacts/5-story-PRDV-14828-view-warnings-in-access-manager.md
spec-author: Derrick Dieso
addendum-author: Dustin Thomason
created: 2026-08-18
status: draft — awaiting Derrick's response on deviations 1-3
---

# Addendum — PRDV-16403 / View Warnings in Access Manager

**This is not a specification.** The specification is Derrick Dieso's `5-story-PRDV-14828-view-warnings-in-access-manager.md`, created 2026-07-27, and it is accepted as authoritative. This addendum carries **only the delta** an implementation investigation surfaced against it: one part that is stale, three deviations that need his confirmation, and four additions his document does not cover.

It exists because `docs/specs/README.md` forbids duplicating a spec, and because the contested points deserve to be a short readable list rather than buried in a rewritten document.

**What needs Derrick's response: deviations 1, 2 and 3.** Everything else is either stale-and-void or an addition that does not contradict him.

---

## 1. Stale — no longer applies

### 1.1 The Sequencing note is void; PRDV-16391 has merged

The spec says:

> *"`cs.warning` / `cs.remarks_html` require the columns on the `Case` entity from PRDV-16391. Land Contact + Firm first; add the case join once 16391 merges — the DTO returns `case`/`caseRemarks` as `null` until then."*

**PRDV-16391 merged.** Commit `53d961ed` is an ancestor of `origin/main`; migration `1786036989067-alter__add_warning_remarks__cases_table.ts` adds `cases.warning` (varchar NULL), `cases.remarks` (text NULL) and `cases.remarks_html` (text NULL); `Case` carries all three at L37-42.

**Consequence:** all four fields are built in one pass. There is no phased delivery.

**Still outstanding, and a different thing:** **PRDV-16392** (the DMS task mapping Lagrange → Callisto) governs whether case data ever *arrives*. So the join works today and returns `null` until 16392 ships. **Code unblocked, data not guaranteed.** This distinction is the root of addition 4.1 below.

---

## 2. Deviations from the spec — these need Derrick's confirmation

### Deviation 1 — the endpoint returns **400**, not 404, for a missing or inactive contact

The spec says:

> *"Missing/inactive contact → 404 (reuse `ValidateContactExists`)."*

These two halves conflict. `ValidateContactExists` throws `BadRequestException` — HTTP **400**:

```ts
// src/granting-client-access/validators/validate-contact-exists.validator.ts
if (contact == null) {
  throw new BadRequestException(CONTACT_NOT_FOUND_MESSAGE);
}
```

The existing sibling transaction-script spec already asserts `BadRequestException`, and `ValidateProceedingExists` behaves identically.

**Taken:** 400, by reusing the validator as instructed. The named mechanism is the more specific instruction, and it matches every sibling in the module.
**Rejected:** honouring the 404, which would mean not reusing the validator and diverging from both siblings.
**If Derrick prefers 404**, it is a small change — a dedicated not-found check in the transaction script — but it makes this endpoint the only one in the module that answers differently for the same condition.

### Deviation 2 — the action carries `@UseGuards(ProceedingsReadAuthGuard)`

The spec says to mirror the `fetch-contact-deliverable-type-grants` stack. That action has **no** `@UseGuards`. Its neighbour — `fetch-client-access-list.action.ts`, same module, same users, same proceeding scope — has one:

```ts
@Get('/proceedingId/:proceedingId/client-access-list')
@FetchClientAccessListSwagger()
@UseGuards(ProceedingsReadAuthGuard)
@TraceSpan()
```

**Taken:** the guard, following the guarded sibling rather than the named one.
**Reasoning:** authorization is the wrong thing to acquire by inference from a template. The unguarded grants-fetch action is recorded separately as a concern for its own ticket; this addendum does not propose changing it.
**This is an addition to Derrick's design, not a correction of it** — his document is silent, so nothing he wrote is being overruled.

### Deviation 3 — the mirror target is `FetchClientAccessListAction`, not the grants action

The spec's stack ordering — *"action → service → transaction script → repository → projection → mapper → DTO → swagger"* — describes a shape the named sibling does not have. `fetch-contact-deliverable-type-grants`:

- has **no mapper** (its projection is structurally identical to its DTO, so none is needed);
- has no guard (deviation 2);
- uses the loose `ParseIntPipe` rather than `new ParseIntPipe({ errorHttpStatusCode: 400 })`.

This endpoint needs a nested DTO **and** a mapper, because the response is `{ case: {...}, contact: {...}, firm: {...}, caseRemarks: {...} }` and the projection is flat.

**Taken:** `FetchClientAccessListAction` as the template. It already has the nested nullable-object DTO, an application-layer mapper (`toFetchClientAccessListResponseDTO`), the guard, and the strict pipe.

**A constraint worth naming, because it fixes where the mapper lives:** the architecture fitness functions run at `severity: error` via `pretest`. `repositories-no-mappers` and `services-no-mappers` mean the mapper cannot sit in the repository or in `ContactsService`; `domain-no-application` means nothing under `domain/` may import the response DTO. So the mapper is application-layer and **the action maps** — exactly as `FetchClientAccessListAction` does, and not as the spec's ordering implies.

---

## 3. Corrections to the ClickUp restatement, not to the spec

Two instructions in the ClickUp ticket are **not** in Derrick's spec and are not being followed. Noted so the difference is visible.

### 3.1 The sanitiser is called bare, per the spec — not with the ticket's allowlist

Derrick's spec §5:

```ts
const sanitizedRemarks = computed((): string => DOMPurify.sanitize(props.html ?? ''));
```

The ClickUp restatement adds an explicit `ALLOWED_TAGS` / `ALLOWED_ATTR` / `FORBID_*` config. That config **adds no security** — the bare call already strips `<script>`, event handlers, `<iframe>`, `<object>` and `<embed>` — while narrowing what survives: as written it would drop `<a>`, `<ul>`/`<li>`, `<h1>`-`<h6>`, `<u>`, `<font>` and the `class` attribute.

**Following the spec.** Dustin ruled (2026-08-18) that formatting the spec does not name is out of scope, which is consistent with the bare call. The repo's only other raw-HTML render (`NotificationBody.vue` L32-43) also passes no config.

**One thing to say out loud:** `.cursor/rules/planetdepos-quasar.mdc` L214 says *"Avoid `v-html` when possible"*. This work brushes that rule either way. It is being done knowingly, behind sanitisation, with the eslint suppression scoped to the one element.

### 3.2 URL builder naming

The ticket says `ACCESS_MANAGER_WARNINGS_URL`. Repo convention for GET builders is `FETCH_*_URL` (`FETCH_CONTACT_DELIVERABLE_TYPE_GRANTS_URL`, `FETCH_DYNAMIC_COLLECTIONS_URL`). Using `FETCH_ACCESS_MANAGER_WARNINGS_URL`.

---

## 4. Additions — behaviour the spec does not cover

None of these contradict Derrick's document; they are gaps found by tracing the code.

### 4.1 `null` carries two meanings and nothing can tell them apart

Every field arrives as `string | null`, and `null` is produced both by *RB holds nothing* and by *PRDV-16392 never mapped this column*. The spec's empty-state rule — *"Empty warnings render the section title plus an italic, 50%-grey 'No warning info'"* — would therefore print a false statement for the two case sections in every environment until 16392 ships.

**The structure cannot resolve this:** the DTO has exactly one representation for both states, so distinguishing them is a change, not a lookup.

**Status: open, deferred to Product.** Dustin is establishing PRDV-16392's status. **The panel is being built to take its empty-state text per section**, so either answer drops in without restructuring — the decision is kept late-binding rather than pre-empted.

### 4.2 The panel's container clips; it does not scroll

The spec requires *"Internal scroll: panel body `overflow-y: auto`, constrained to overlay height via the existing `.rightColumn` flex layout."* `.rightColumn` is **`overflow: hidden`**:

```scss
.rightColumn { flex: 1 1 44%; min-width: 0; display: flex; flex-direction: column;
               min-height: 0; overflow: hidden; padding: 1.5rem; /* … */ }
```

So the requirement is not satisfiable by the existing layout. **`RbWarningsPanel` gets its own inner element** with `flex: 1; min-height: 0; overflow-y: auto`. Without it long content clips silently — no scrollbar, no overflow indication.

### 4.3 The freshness options over-specify; one of the three does the work

The spec asks for `staleTime: 0`, `gcTime: 0`, `refetchOnMount: 'always'`. Tracing the lifecycle: the overlay renders under `v-if="isGcaEnabled && accessManagerContact"` and `handleAccessManagerAfterLeave` nulls the contact — so **it unmounts on close and remounts on open**. `refetchOnMount: 'always'` therefore fires every open regardless of `staleTime`, making `staleTime: 0` redundant.

**`gcTime: 0` is the one that earns its place**: it prevents a previous contact's cached warnings painting for a frame before the refetch resolves. For a warning, briefly showing the wrong contact's caution is a real failure. Note `gcTime` appears **nowhere else in this repo**, so this is a deliberate novelty.

All three are being kept — they are harmless and match the spec — but the reasoning is recorded so nobody removes the load-bearing one as redundant.

### 4.4 The three source columns are not shaped alike

`contacts.warning` and `firms.warning` are **NOT NULL `varchar`** and may be `''`. `cases.warning` is **nullable `varchar`**; `cases.remarks_html` is **nullable `text`**. The spec says only *"Mapper normalizes empty/whitespace → `null`"*.

**The mapper collapses `null`, `''` and whitespace-only to `null`**, across both column contracts. Asserted directly in the mapper spec.

### 4.5 Two entry points, and one fabricates its contact

The Access Manager opens from two places, and the spec treats it as one:

| Trigger | Handler | Contact object |
| --- | --- | --- |
| Contact search panel | `handleAddContactFromSearch` (`ProceedingDetailPage.vue` L103) | a real `ContactSearchItem` |
| Client Access list row | `handleEditAccessFromList` (L114) | **a synthetic `ContactSearchItem` built from a `ClientAccessContact`** |

Both are exercised in the test plan. Completeness: `isAccessManagerOpen` is set `true` at exactly L106 and L117; the overlay renders from one call site.

### 4.6 Retiring `warningsPlaceholder` breaks an existing test

`AccessManagerOverlay.spec.ts` L177-188 asserts both `data-testid="rb-warnings-panel"` and the `warningsPlaceholder` i18n key. That assertion is updated deliberately, not incidentally. Note the testid **stays on the overlay's `<section>`** — it is not moved onto the new component — and `warningsTitle` plus the close button stay in the overlay's own `<header>`, outside the replaced content, so the new panel renders **section titles only**.

### 4.7 The warnings query must not feed the overlay's loading state

`<Overlay :loading="isLoading">` currently draws only from `useAccessManager`. Folding the warnings fetch into it would let a slow warnings request block the entire access flow — which would defeat the spec's own non-blocking-error requirement. Warnings loading renders **inside the panel**.

### 4.8 Integration-test seeders need extending

Repository specs here are real-Postgres `*.integration.spec.ts`, excluded from `npm test` and run by `npm run test:integration`. The existing seeders cannot express this feature's cases: `seedContact` and `seedFirm` hardcode `warning` to `''` with no override, `seedProceeding` inserts its `jobs` row with **no `case_id`**, and **no `case.test-seeder.ts` exists**. All four are extended as part of this work.

---

## 5. Unchanged from the spec

Recorded so the scope of this addendum is unambiguous. Everything below is implemented exactly as Derrick specified:

- The HTTP route, verb and path.
- The response shape `{ case: { warning }, contact: { warning }, firm: { warning }, caseRemarks: { html } }`.
- Section order: Case → Contact → Firm → Case Remarks.
- Both repository queries, including which join is INNER and which is LEFT, and the `firm.id = contact.account_id` relationship.
- Folder layout, class names, and the projection carrying `AccessManagerWarningsProjection` + `AccessManagerWarningsResult`.
- `ContactsService.fetchAccessManagerWarnings(params)`; registry and `forFeature` additions.
- The bare sanitiser call (§3.1).
- Non-blocking error handling.
- Read-only in Atlas — and note this is **structural**, not a UI choice: `Contact`, `Firm` and `Case` all extend `ImportedBaseEntity`, so Callisto has no write path to these values.
- The feature flag: `IS_GRANTING_CLIENT_ACCESS_ENABLED`, already gating the overlay at the parent. **No additional gating is added** — a redundant check inside the overlay would break its spec, which does not mock the flag composable.

## 6. Known delivery risk, outside the spec

Manual verification has no route today. `IsFeatureAllowedTS` documents that feature access follows Cognito token claims only with no server-side override; PRDV-16312 already shipped an acceptance criterion undemonstrated for this reason, recording that setting the flag did not survive a re-login; and the `CALLISTO_DEV_FEATURE_FLAG_OVERRIDES` workaround another changelog records **does not exist in either repo**. Tracked as concern C4 / LD-007. If the ticket ships without manual proof, the PR says so plainly rather than leaving it implied.
