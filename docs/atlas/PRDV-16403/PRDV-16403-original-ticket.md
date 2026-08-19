# Display Firm, Case, Contact & Case Remarks in Access Manager - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | PRDV-16403 |
| Captured on | 2026-08-18 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-16403 |

## ClickUp Location

MBL LIST > Sprint 2026-17 (8/19-9/1)

## Ticket Metadata

| Field | Value |
| --- | --- |
| Status | READY FOR WORK |
| Assignees | DT Dustin Thomason |
| Dates | Start Due |
| Priority | High |
| Sprint points | 3 |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |
| Tags | No visible value in the active ClickUp page |

## Activity And Comments

_Visible ClickUp activity and comments captured from the active browser page. Attachments and embedded media are not retrieved._

- **Comment by Derrick Dieso** - Aug 11 at 4:42 pm
  Nah sorry @Anastasiya Savchuk I'm newer to creating Epics here, will incorporate QA review in the future!
  
  For the questions
  
  1 - @Shaye Lankford can you get Michael Carrigan's input on what we want to display when empty? Unless you have an opinion off hand?
  
  2 - We should show an error message, @Shaye Lankford please provide copy and I'll then add this as an AC
  
  3 -
  
  Survived items - styles, <img>, <table>, <tr>, <td>
  
  Stripped items - <scripts>, event handlers, <iframe>, <object>, and <embed>
  
  4 - @Shaye Lankford any opinions here? the default is to display as is

- **Activity:** This task is unblocked by Replicate Case Warning & Case Remarks from RB9 into Callisto (Lagrange → Callisto) Aug 13 at 5:59 am

- **Comment by Shaye Lankford** - Yesterday at 9:06 am
  Hey @Anastasiya Savchuk, @Derrick Dieso
  
  - I think we leave it as "No remarks info" when empty. They're thought of and referenced differently by different users
  - Timeout errors can show "Warnings/remarks failed to load"
  - n/a
  - I don't believe there are images or tables in this section - if there are, their styling does not require support for this first iteration. It should just be text with CSS styling (color, bolding, font size, etc)

- **Comment by Derrick Dieso** - Yesterday at 11:36 am
  Thanks @Shaye Lankford ACs and spec have been updated reflecting this

- **Activity:** Kat Giangiulio also added subtask to Sprint 2026-17 (8/19-9/1) 12:20 pm

- **Activity:** Kat Giangiulio assigned to: You 12:21 pm

- **Activity:** Kat Giangiulio added follower: You 12:21 pm

## Original Request

**Story of epic PRDV-14828 — View Warnings in Access Manager**

As an Ops Atlas user, I want to see firm, case, and contact warnings plus case remarks in the right-hand panel of the Access Manager, so that I can reference delivery details without opening RB.

This story covers the **surfacing** work — the Callisto read endpoint + the Atlas FE panel — for all four sections. It does ** not** cover replicating the case fields into Callisto (PRDV-16391) or the DMS/IaC enablement (PRDV-16392).

## Acceptance Criteria

- Right-hand panel of the Access Manager shows, in order: **Case Warning → Contact Warning → Firm Warning → Case Remarks**.
- Case = Case Warning for the proceeding being viewed; Contact = warning for the contact being granted; Firm = warning for that contact's firm.
- Case Remarks preserve HTML/CSS styling from RB, sanitized before render. **Survives:** inline `styles`, `<img>`, `<table>`, `<tr>`, `<td>`. ** Stripped:** `<script>`, event handlers (e.g. `onclick`), `<iframe>`, `<object>`, `<embed>`.
- No images or tables are expected in the remarks field (confirmed with stakeholders). First iteration renders **text with CSS styling only** (color, bolding, font size); anything that survives sanitization renders as-is with no dedicated image/table styling support.
- Styling matches [Figma](https://www.figma.com/design/RaMfbhcLeHdgF6svVOYusR/Planet-Depos-Atlas?node-id=10285-154183&t=Aj8onofQq8f3d32V-0) (Case Remarks not in Figma — confirm with Product).
- Internal scroll bar when content exceeds panel height.
- Read-only in Atlas from the corresponding RB fields.
- Data fetched fresh each time the Access Manager opens (not cached mid-session).
- If the warnings/remarks fetch fails (500 / timeout), the panel shows an error message **"Warnings/remarks failed to load"** in place of the sections.
- Empty warning → title + "*No warning info*" (italic, 50% grey). Empty Case Remarks → "* No remarks info*" (intentional distinct wording — warnings and remarks are referenced differently by users).

## Key facts

- **Access Manager = the GCA overlay** `AccessManagerOverlay.vue`. The right-hand panel ** already exists** (`data-testid="rb-warnings-panel"`, placeholder `accessManager.warningsPlaceholder`). This story fills it.
- Overlay already has context props: `contact` (id, fullName, email, firmName), `firmName`, `caseName`, `jobNumber`, `proceedingName`, `proceedingId`.
- **Contact + Firm warnings already exist** in Callisto (`contacts.warning`, `firms.warning`, RB9-replicated). Firm resolves via `firm.id = contact.account_id`.
- **Case Warning + Case Remarks** columns (`cases.warning`, `cases.remarks_html`) are added by ** PRDV-16391**; this story wires them but they return `null` until 16391 lands. Contact + Firm ship immediately.

## Backend (callisto-back-end)

New read-only endpoint under `granting-client-access/contacts`, mirroring the `fetch-contact-deliverable-type-grants` stack (action → service → transaction script → repository → projection → mapper → DTO → swagger).

**Endpoint:** `GET /callisto/granting-client-access/contacts/contactId/:contactId/proceedingId/:proceedingId/warnings`

### Files to create

- `contacts/domain/projections/access-manager-warnings.projection.ts` — `AccessManagerWarningsProjection` + `AccessManagerWarningsResult` (`contactWarning`, `firmWarning`, `caseWarning`, `caseRemarksHtml: string | null`).
- `contacts/infrastructure/repositories/access-manager-warnings.repository.ts` — inject `@InjectRepository(Contact)` + `@InjectRepository(Proceeding)` (mirror `ClientAccessListRepository`).
- Contact+firm: `from Contact c LEFT JOIN Firm f ON f.id = c.account_id WHERE c.id = :contactId AND c.is_active = true` → `c.warning`, `f.warning`.
- Case: `from Proceeding p INNER JOIN Job j ON j.id = p.job_id LEFT JOIN cases cs ON cs.id = j.case_id WHERE p.id = :proceedingId` → `cs.warning`, `cs.remarks_html` (`job.case_id` nullable → LEFT JOIN).
- `contacts/domain/transaction-scripts/fetch-access-manager-warnings-ts/` → `.transaction.script.ts` + `.param.ts` (reuse `ValidateContactExists` for 404).
- `contacts/application/controllers/actions/access-manager-warnings-action/` → `fetch-access-manager-warnings.action.ts`, `access-manager-warnings.response.dto.ts`, `access-manager-warnings.swagger.ts`, `access-manager-warnings.mapper.ts`.

**Response DTO shape:**

{

 case: { warning: string | null },

 contact: { warning: string | null },

 firm: { warning: string | null },

 caseRemarks: { html: string | null }

}

Mapper normalizes empty/whitespace → `null` (RB `warning` columns are NOT NULL varchar and can be empty).

### Files to modify

- `ContactsService`: add `fetchAccessManagerWarnings(params)`.
- `registries/action.registry.ts`, `registries/transaction-script.registry.ts`, `registries/repository.registry.ts`: register new action/TS/repo.
- `granting-client-access.module.ts`: add `Case`, `Job`, `Proceeding` to `TypeOrmModule.forFeature([...])` (Contact + Firm already present).

### Sequencing note

`cs.warning` / `cs.remarks_html` require the `Case` entity columns from **PRDV-16391**. Land Contact + Firm first; add the case join when 16391 merges (DTO returns `case`/`caseRemarks` as `null` until then).

### Tests (`__specs__`, `.spec.ts`)

- Repository integration: contact+firm warnings; empty → null; contact w/ no firm; proceeding w/ null `case_id`; missing contact.
- Mapper: empty/whitespace → null.
- Action + TS: happy path DTO; 404; 400 on bad params.

## Frontend (atlas-front-end)

### Files to create

- `src/callisto/types/access-manager-warnings.ts` — `AccessManagerWarnings` type.
- `src/callisto/api/requests/accessManagerWarnings.ts` — `fetchAccessManagerWarnings(contactId, proceedingId)` via `useApiRequest` (mirror `contactDeliverableTypeGrants.ts`).
- `.../AccessManagerOverlay/composables/useAccessManagerWarnings.ts` — Vue Query; `queryKey: [ACCESS_MANAGER_WARNINGS_QUERY_KEY, contactId, proceedingId]`; **fresh each open:** `staleTime: 0`, `gcTime: 0`, `refetchOnMount: 'always'`; `enabled: isOpen && contactId != null`.
- `.../AccessManagerOverlay/components/RbWarningsPanel.vue` — sections in order Case → Contact → Firm → Case Remarks; renders error state (`warningsLoadError`) when the query errors; `<script>` before `<template>`; typed props/emits; SASS module.
- `.../AccessManagerOverlay/components/RbWarningsPanel.module.scss` — internal scroll (`overflow-y: auto`), empty-state (italic, 50% grey), contained CSS for remarks (`max-width: 100%`).

### Files to modify

- `src/callisto/api/constants.ts`: add `ACCESS_MANAGER_WARNINGS_URL(contactId, proceedingId)`.
- `src/callisto/api/queryKey.ts`: add `ACCESS_MANAGER_WARNINGS_QUERY_KEY = 'accessManagerWarnings'`.
- `AccessManagerOverlay.vue`: replace placeholder `<p>` in `section.rightColumn` with `<RbWarningsPanel>`; call `useAccessManagerWarnings({ isOpen: () => props.modelValue, contactId, proceedingId })`; pass warnings + loading/error (render `warningsLoadError` on error).
- `src/i18n/en-US/common.json` (`common.callisto.accessManager`): add `caseWarningTitle`, `contactWarningTitle`, `firmWarningTitle`, `caseRemarksTitle`, `noWarningInfo`, `noRemarksInfo`, `warningsLoadError` ("Warnings/remarks failed to load"); remove reliance on `warningsPlaceholder`.

### Case Remarks HTML rendering

Sanitize with **DOMPurify** (`^3.2.6`) before render, reusing `src/globalComponents/Notifications/components/NotificationBody.vue`. Pass an explicit allowlist reflecting the sanitization decision — keep `styles`/`<img>`/`<table>`, strip scripts/handlers/iframe/object/embed:

const sanitizedRemarks = computed((): string =>

 DOMPurify.sanitize(props.html ?? '', {

 ALLOWED_TAGS: ['img', 'table', 'tr', 'td', 'span', 'div', 'p', 'b', 'strong', 'i', 'em', 'br'],

 ALLOWED_ATTR: ['style'],

 FORBID_TAGS: ['script', 'iframe', 'object', 'embed'],

 FORBID_ATTR: ['onerror', 'onclick', 'onload'],

 })

);

// <div v-html="sanitizedRemarks" /> inside a CSS-contained wrapper

(Exact allowlist can be refined at implementation; intent is pinned — keep styles/img/table, strip scripts/handlers/iframe/object/embed.) Never bind raw RB HTML; no external RB stylesheets.

### Tests

- `useAccessManagerWarnings.spec.ts`: fires on open; refetches on reopen (not cached); disabled when contactId null.
- `RbWarningsPanel.spec.ts`: renders each section + values; empty state; error state renders `warningsLoadError` on fetch failure; sanitizes remarks HTML (`<script>` + event handlers stripped, `styles`/`<img>`/`<table>` retained); section order; internal scroll wrapper.

## Dependencies

- ⛓️ **PRDV-16391** (Lagrange → Callisto replication) — adds `cases.warning` + `cases.remarks_html`; blocks the Case Warning + Case Remarks portions of this story.
- ⛓️ **PRDV-16392** (IAC / DMS) — blocks PRDV-16391.

## Suggested point range

**Medium** — one new read endpoint (no writes/migrations) + one FE panel/composable/sanitized render/i18n, with tests both sides. Panel shell + overlay context already exist.

## Explicit Constraints In Original Request

- _Review the Original Request section above; constraints are preserved there when present._

## Context Paths In Original Request

- _Review the Original Request section above; paths and links are preserved there when present._

## Downstream Artifacts

- Investigation: Not created yet
- Spec: Not created yet
- Q and A ledger: Not created yet
