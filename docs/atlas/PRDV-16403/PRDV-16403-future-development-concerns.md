---
ticket: PRDV-16403
created: 2026-08-18
phase-opened: Phase 1 (recon) / recorded Phase 2
---

# Future-development concerns — atlas/PRDV-16403

Dated, evidence-backed record of risks identified during this ticket and **not** resolved in scope. Kept out of the [investigation report](./investigations/PRDV-16403-investigation.md) and the spec so they stay lean. Concerns are not blockers — where one *should* block, that is said explicitly.

---

## C1 — The firm whose warning is shown and the firm name it is shown under are resolved by two different paths, and nothing reconciles them

**Status:** **downgraded — risk substantially refuted 2026-08-18 (Phase 3 reconcile)**; kept on record, see the resolution note at the foot of this entry · **Verified in code:** 2026-08-18 · **Created by this ticket:** no — this ticket is the first surface where the mismatch becomes *visible to a user*, but the divergence already exists.

### Executive summary (stands alone)

The Access Manager will show a warning labelled as belonging to a particular law firm. The **warning text** is fetched by the backend for the firm it resolves from the contact's `account_id`. The **firm name** printed beside it comes from a completely separate frontend path that never learns the firm's id at all. Nothing in the system checks that the two refer to the same firm.

If they ever disagree, an Ops user reads a caution about firm *A* under firm *B*'s name — and acts on it. For a feature whose entire purpose is conveying cautions before granting a client access to legal deliverables, a mislabelled warning is worse than a missing one: a missing warning prompts a check in RB, a wrong one does not.

**Decision requested:** accept for this iteration, or add a firm id to the two frontend types and assert the match. Options below.

### Evidence

- The backend resolves the firm by join: `leftJoin(Firm, 'firm', 'firm.id = contact.account_id')` — `callisto-back-end/src/granting-client-access/contacts/infrastructure/repositories/client-access-list.repository.ts`, and the same clause is prescribed for the new warnings query.
- `contact.account_id` is `@Column({ name: 'account_id', type: 'integer' })` with **no foreign key** — `src/shared/shared-entities/entities/contacts/contact.entity.ts:19`. That is not incidental: the existing integration spec tests the "no firm" case precisely by seeding a **dangling** `accountId: 424242`.
- The frontend never holds a firm id. `ContactSearchItem` is `{ id, fullName, email, firmName: string | null }` — `atlas-front-end/src/callisto/types/contact-search.ts:1-6`. `ClientAccessFirm` is `{ name, streetAddress, city, state }` — `src/callisto/types/client-access-list.ts:1-6`. **Neither carries `id`.**
- The overlay receives the name as a separate prop, sourced differently per entry point: `handleAddContactFromSearch` takes `contact.firmName` from the search response (`ProceedingDetailPage.vue:103-108`); `handleEditAccessFromList` takes `contact.firm?.name` from the client-access-list response and **fabricates** the contact object (`:114-121`).

### Why it matters (fallout, not probability)

> **Superseded in part by the Resolution note below (2026-08-18).** The "not verified" claim in the next paragraph was true when written and is no longer — the trace closed. Original text kept per this artifact's dated-record convention; read the Resolution note for the current position.

Probability is likely low — both paths ultimately derive from the same `account_id` join *where verified*. But **one of the two paths has not been verified**: the `search-contacts` projection's `firmName` derivation was not read, and that is the path feeding entry point 1. That unverified gap is recorded as a frontier item in the [coverage ledger](./investigations/PRDV-16403-coverage-ledger.md).

Fallout if it does diverge: silent and unfalsifiable from the UI. There is no id displayed, so nobody can spot the mismatch by looking. It would surface only as an Ops user acting on the wrong caution — the exact failure this feature exists to prevent.

### Options

1. **Accept for this iteration.** Cheapest. Justified if the frontier trace confirms both projections use the same join. **Requires** closing that trace first — accepting on an unverified assumption is not the same as accepting a known small risk.
2. **Assert the match.** Add `firmId` to `ClientAccessFirm` and `ContactSearchItem` (and their Callisto projections), pass it to the endpoint, and have the backend confirm the resolved firm matches. Correct, and wider than this ticket.
3. **Remove the ambiguity instead.** Have the warnings endpoint return the firm **name** alongside its warning, and have the panel label the section from *that* rather than from the separately-sourced prop. Cheaper than option 2, self-consistent by construction, and confined to this ticket's own new surface. **Recommended if the risk is not accepted.**

### Resolution note — 2026-08-18 (Phase 3 reconcile)

**The unverified half is now verified, and it closes the gap.** The frontier item this entry depended on — whether the `search-contacts` path derives `firmName` from the same join — was traced:

- `ContactsRepository` (the search path, feeding entry point 1) uses `leftJoin(Firm, 'firm', 'firm.id = contact.account_id')` and selects `firm.name AS "firmName"` — `src/granting-client-access/contacts/infrastructure/repositories/contacts.repository.ts:51,56`.
- `ClientAccessListRepository` (feeding entry point 2) uses the identical clause — `client-access-list.repository.ts`.

So **both** frontend sources of the firm name resolve from the *same* `contact.account_id → firm.id` edge that the new warnings query will use. The name and the warning cannot disagree about which firm they describe.

**What survives:** only a narrow race — if a contact's `account_id` were repointed between the request that supplied the name and the request that fetched the warning, the two would describe different firms. That is inherent to any two-request read, is not specific to this feature, and involves replication rewriting a contact's firm mid-session.

**Disposition:** **option 1 (accept for this iteration) is now justified**, because its stated precondition — closing the trace — has been met. Option 3 (return the firm name alongside its warning) remains the cheap hardening if anyone wants the two to be self-consistent by construction rather than by convention; it is no longer a correctness fix.

**Kept on record rather than deleted** so a future reader sees that the two-path resolution was noticed, traced, and found benign — not overlooked.

---

## C2 — `FetchContactDeliverableTypeGrantsAction` has no authorization guard while its read-side sibling does

**Status:** open · **Verified in code:** 2026-08-18 · **Created or widened by this ticket:** **no** — recorded because this ticket reads the same code and must decide whether to copy the pattern.

**The finding:** `fetch-contact-deliverable-type-grants.action.ts` carries `@Get(...)`, its swagger helper and `@TraceSpan()`, but **no `@UseGuards`**. Its sibling `fetch-client-access-list.action.ts` carries `@UseGuards(ProceedingsReadAuthGuard)`. Both are proceeding-scoped reads in the same module, reached by the same users, and only one is guarded.

**Why it is recorded here rather than fixed:** it is pre-existing, outside this ticket's scope, and fixing it changes the authorization surface of a live endpoint — that deserves its own ticket and its own regression thinking, not a drive-by in a read-only feature.

**Why it is recorded at all:** this ticket must choose a template, and the request tells it to mirror the **unguarded** one. Following that instruction would propagate the gap to a second endpoint. Decision **D3** exists for exactly this reason, and the recommendation is to follow the guarded sibling instead.

**Follow-up:** worth a ticket to decide whether the grants read should be guarded. Not raised as a security escalation because the endpoint sits behind the same authenticated `@ContactsController()` surface — the concern is inconsistency and the drift it invites, not open access.

---

## C3 — Inherited: the rename guard authorizes on a client-supplied `trackTypeId` that is never cross-checked

**Status:** open, inherited · **Not verified by this ticket** · **Created by this ticket:** no · **Touched by this ticket:** no

Recorded for continuity only. PRDV-16313's coverage ledger left this on its frontier: `UpdateDeliverableFileAuthGuard` authorizes off `request.body.trackTypeId` while the transaction script reads the file's real `trackTypeId` from the database, so the value authorized against and the value acted on are not proven to be the same.

**Relevance here:** none, deliberately. This ticket's guard decision (**D3**) points at the **read-side** `ProceedingsReadAuthGuard`, not the update guard, so the pattern is not inherited. The entry exists so that a future reader who does reach for `UpdateDeliverableFileAuthGuard` as a template finds the flag already raised — and so that this ticket's decision not to touch it is on the record rather than looking like an oversight.

**Owner:** unassigned. Belongs with whoever picks up the remaining epic events (PRDV-16313's frontier lists five).

---

## C4 — Manual verification of GCA features is blocked, and the documented workaround does not exist

**Status:** open · **Verified in code:** 2026-08-18 · **Created by this ticket:** no · **Blocks this ticket's manual proof:** **yes** — see the summary.

### Executive summary (stands alone)

Features behind the `IS_GRANTING_CLIENT_ACCESS_ENABLED` flag cannot currently be demonstrated locally. A prior ticket already hit this and shipped an acceptance criterion undemonstrated. The workaround recorded in a second ticket's changelog **does not exist in either codebase**. Unless someone resolves flag provisioning, this ticket will also ship without a human ever having seen it work.

This is the one concern in this file that **should** influence whether the ticket is called done, and it needs an owner with access to Cognito configuration.

### Evidence

- `callisto-back-end/src/feature-flag/domain/transaction-scripts/is-feature-allowed-ts/is-feature-allowed.transaction.script.ts` carries a class-level JSDoc stating it outright: *"Feature access follows **Cognito token claims only** (`identity.featureFlags`). There is no server-side env override; flags must be assigned in Cognito/Atlas for every environment including local."* The body reads `user.identity?.featureFlags` and returns `false` when absent.
- `atlas-front-end/src/callisto/auth/composables/featureFlags/useFeatureFlags.ts` simply fetches the list from Callisto — no local override path.
- `grep -rn "DEV_FEATURE_FLAG_OVERRIDES|FEATURE_FLAG_OVERRIDE"` across `atlas-front-end` returns **nothing**, refuting the `CALLISTO_DEV_FEATURE_FLAG_OVERRIDES` workaround recorded in `docs/atlas/PRDV-15776-changelog.md`.
- PRDV-16312's test plan records the consequence in its own words: an acceptance criterion *"not demonstrated — blocked on the GCA feature flag"*, and *"Setting it did not survive a re-login in the attempt made — unresolved."*

### Why it matters

The feature's whole risk profile is visual and stateful — empty versus failed, order, scroll, sanitised rendering. Automated tests can cover every one of those in isolation, and none of them proves an Ops user can read a warning in a browser. Report §7 rates feedback speed as slow for exactly this reason: a wrong empty-state decision (**D1**) could sit unnoticed for weeks.

### Options

1. **Provision the flag properly** — assign `IS_GRANTING_CLIENT_ACCESS_ENABLED` to a dev Cognito user and establish why the prior attempt did not survive re-login. Unblocks this ticket and every future GCA ticket. Requires Cognito access.
2. **Ship on automated coverage with the gap stated.** Legitimate only if said plainly in the PR and the review summary — "no acceptance criterion was demonstrated against a running system" — rather than implied by silence.
3. **Add a documented local override.** Contradicts the explicit JSDoc above and would weaken a production authorization path. **Not recommended**, and recorded here so the option is visibly rejected rather than quietly unconsidered.

**Tracked as decision D7.** Owner: Dustin / Product.

---

## C5 — The contact search gives no signal that Enter is required, and renders nothing at all until it is pressed

**Status:** open · **Verified in code:** 2026-08-22 · **Created or widened by this ticket:** **no** — pre-existing in a component this ticket does not touch. Recorded because it cost real time during this ticket's manual validation and presented as a defect.

**The finding:** the contact search in `ContactManagementPanel.vue` is search-on-submit, and nothing in the UI says so.

The input binds to `searchInput` (L27, L103). The query is handed a *different* ref, `submittedSearchTerm` (L28, L39), and `useSearchContacts` disables itself while that ref is empty (`useSearchContacts.ts` L32, L78). The only thing that copies one ref into the other is `commitSearch` (L78-80), reachable solely through `@keyup.enter` (L100).

Three things then combine to leave the user with no feedback at all:

- The placeholder reads `Search for contact name` (`common.json` → `callisto.contactManagement.searchPlaceholder`) and does not mention Enter.
- The magnifier is a decorative `q-icon` in the input's `#prepend` slot (L106-107) with no click handler, so it looks like a search control and does nothing when clicked.
- Every status message is gated on `hasSubmitted` (L41-42, L47, L52). Before Enter, the spinner, the `No contacts found.` message and the error message are all suppressed and the results list is empty. The panel renders **nothing** — there is no state distinguishing "you have not searched yet" from "the search is broken".

**Observed during this ticket (2026-08-22):** typing a seeded contact's name into the panel produced an empty result area and read as a failure of the seeded data or of the new endpoint. Browser inspection confirmed no search request had been issued at all — because none was supposed to have been. The time went into diagnosing a component that was working correctly.

**Why it is recorded here rather than fixed:** `ContactManagementPanel.vue` is pre-existing shipped UI outside this ticket's scope, and the fix is a copy-and-affordance change owned by whoever owns that panel's design — not a drive-by in a read-only warnings feature.

**What would resolve it** — any one of these closes the gap, cheapest first:

1. Change the placeholder to name the interaction, e.g. `Search for contact name and press Enter`. One locale string, no logic touched.
2. Render a pre-submit prompt where the status messages already render, shown when `!hasSubmitted`, so an untouched panel says something rather than nothing.
3. Make the magnifier a real submit control that calls `commitSearch`, so the icon that looks clickable is.

**Why it matters beyond this ticket:** the same silent-empty pattern will read as a defect to every new user of the Access Manager, and to every future engineer validating a feature that depends on finding a contact first. The cost is not a broken feature; it is repeated misdiagnosis of a working one.

**Owner:** unassigned. Belongs with the client-access UI design owner — worth raising alongside the outstanding copy questions already open on this ticket.

---

## C6 — DOMPurify does not sanitize correctly under happy-dom, so nothing in Atlas verifies its XSS protection

**Status:** open · **Verified in code:** 2026-08-24 · **Created by this ticket:** no — the defect is in the shared test environment; this ticket is the first place it was noticed.

### Executive summary (stands alone)

Atlas renders backend-authored HTML through `v-html` in two places: the pre-existing `src/globalComponents/Notifications/components/NotificationBody.vue`, and this ticket's `RbWarningsPanel.vue` (RB case remarks). Both rely on `DOMPurify.sanitize` as the only thing standing between backend content and the DOM.

Under the repo's `happy-dom` test environment, DOMPurify does **not** behave: probed directly, it strips safe tags while letting `<script>` and `<iframe>` through. So a spec cannot assert that sanitization works — and neither `v-html` site has ever had that assertion. `RbWarningsPanel.spec.ts` works around it by mocking `dompurify` and asserting only what the component owns (that RB html is always routed through the sanitizer and never bound raw), which is the right scope for a component spec but leaves the sanitizer itself unverified repo-wide.

This is a test-environment defect, not a production one — DOMPurify is expected to behave correctly in a real browser. The risk is that a future regression in sanitization (a version bump, a config change, a new `v-html` site bound raw) would not be caught by any test.

### Evidence

- `RbWarningsPanel.spec.ts:12-15` — the mock and the comment recording the happy-dom behaviour.
- `NotificationBody.vue:32-34` — the pre-existing `DOMPurify.sanitize` call; its spec makes no sanitization assertion.
- Both sites use the same `<!-- eslint-disable vue/no-v-html -->` shape, so the pattern is established and will be copied again.

### Options

1. **Accept, documented.** What this ticket does. The component-level assertion (routed through the sanitizer, never bound raw) is the part a component spec can own, and it is in place for the new surface.
2. **Add a jsdom-environment spec for sanitization.** Vitest allows a per-file environment via a docblock; one small spec run under `jsdom` could assert `<script>`/`<iframe>` stripping for real, covering both `v-html` sites. Cheapest real fix.
3. **Investigate the happy-dom interaction.** Establish whether it is a version issue or a known incompatibility, and decide the repo's environment accordingly. Widest, and properly a repo-level decision rather than this ticket's.

**Recommended:** option 2, as follow-up work — it restores the missing guarantee without changing the repo's test environment.

**Why it matters beyond this ticket:** `v-html` + DOMPurify is now the established pattern for rendering backend HTML in Atlas, and the next engineer will copy it. Whether the sanitizer actually sanitizes is a repo-wide guarantee, not a per-feature one, so it should not be decided inside a feature branch.

**Owner:** unassigned. Belongs with whoever owns the Atlas test-environment configuration.
