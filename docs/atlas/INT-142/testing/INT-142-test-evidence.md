# INT-142 — Test evidence (Playwright, local stack)

**Status: pass.** Every acceptance criterion is shown on the local stack. Run on 2026-10-13, 15:41–15:44 UTC.

Playwright drove the signed-in Chrome over CDP (`--remote-debugging-port=9222`, profile `C:/temp/atlas-cdp`), each step in its own new tab, so the user's own tabs were not touched. Proceeding 3001 `Deposition - John Smith`, job 112233, case `Smith v. Jones`. Contact 800002 `Caitlin Crouse`.

## Stack under test

| Service | Checkout | Code | Running |
| --- | --- | --- | --- |
| callisto-back-end | main checkout, branch `INT-142` | `94f2f8a0` (= `origin/INT-142`, PR #481) | :3004, started 11:35 local, after the 11:32 checkout. `dist` has `contact-access-audit.dispatcher.js` and `contact-access-audit.module.js` (11:35:14), and `contacts.service.js` calls `contactAccessAuditDispatcher` |
| europa-back-end | main checkout, branch `main` | `434567f` (no INT-142 change, V-07) | :3006, started 11:32 local |
| atlas-front-end | main checkout, branch `INT-142` | `96a5354e` (= `origin/INT-142`, PR #601) | :9000 (`quasar dev`), started 11:33 local |

**Configuration** (presence only, no values printed): callisto's `SQS_AUDIT_EVENT_URL_OUTBOUND` in `.env` and `.env.local` is not `null` and equals europa-back-end's `SQS_AUDIT_EVENT_URL_INBOUND` in `.env`.

## Test data

No setup rows were needed. Proceeding 3001, contact 800002 and the deliverable types already exist locally. The contact had no grants on proceeding 3001 before the run (`callisto.deliverable_access_grants` was empty).

## Steps and results

| # | Step | Observed |
| --- | --- | --- |
| 1 | Proceeding page → Client access → Add access → search `Caitlin` → add Caitlin Crouse. In the Access Manager, turn on **MP4 Video › DepoView** and **Planet Suite › Planet Draft**, then Save | The request is `POST /callisto/granting-client-access/contacts/deliverable-type-grants` with `{"contactId":800002,"proceedingId":3001,"selections":[{"deliverableCollectionId":null,"deliverableTypeId":38},{"deliverableCollectionId":2,"deliverableTypeId":28}]}`. It returned `200`, with selections MP4 Video › DepoView and Planet Draft. Caitlin Crouse appears in the Client access table |
| 2 | Europa `/europa-stuff?type=CLIENT_ACCESS_UPDATED` | One row. Event Type `CLIENT_ACCESS_UPDATED`, User Email `dustin.thomason@planetdepos.com`, User Name `Dustin Thomason`, Resource `Caitlin Crouse`, Resource Type `CONTACT`, Date `2026-10-13 11:42:50` (local; `createdAt` `2026-10-13T15:42:50.894Z`), Bucket blank. The Path has five bold-labelled lines: **Case:** Smith v. Jones · **Job:** 112233 · **Proceeding:** Deposition - John Smith · **Access granted:** MP4 Video › DepoView, Planet Draft · **Access revoked:** N/A. `serviceName` is `callisto` |
| 3 | Client access row menu → Edit access → turn off MP4 Video › DepoView → Save | The request has selections `[{"deliverableCollectionId":null,"deliverableTypeId":38}]` and returned `200`, with only Planet Draft left |
| 4 | Europa, same filter | Two rows, newest first. The new row (`2026-10-13 11:43:03`, `createdAt` `15:43:03.336Z`) reads **Access granted:** N/A · **Access revoked:** MP4 Video › DepoView, with the same Case / Job / Proceeding, user and Resource |
| 5 | Europa Event Type and Resource Type dropdowns; filter by Resource Type `CONTACT` | Event Type options end with `CLIENT_ACCESS_UPDATED` (14 options). Resource Type options: `CONTACT`, `FILE`, `FOLDER`, `PERMISSION`, `PROCEEDING`, `USER`. `?resourceType=CONTACT` returns exactly the 2 `CLIENT_ACCESS_UPDATED` / `CONTACT` rows |
| 6 | Edit access again with nothing changed | The overlay shows **Access to:** Case: Smith v. Jones · Job number: 112233 · Proceeding: Deposition - John Smith, matching the path. Planet Draft is on, and **Save is disabled**, so a save that changes nothing can't be sent from the UI. Cancelled; nothing saved |

## Screenshots (`screenshots/`)

| Screenshot | Shows | Acceptance criteria |
| --- | --- | --- |
| `01-access-manager-grant-selections.png` | The Access Manager with MP4 Video › DepoView turned on, just before Save | Granting access action taken |
| `02-client-access-after-grant.png` | The Client access table listing Caitlin Crouse after the save | To whom the types were granted |
| `03-europa-grant-row.png` | Europa, filtered to `CLIENT_ACCESS_UPDATED`: the grant row with user, date, Resource `Caitlin Crouse`, Resource Type `CONTACT`, and the five-line path with **Access granted:** MP4 Video › DepoView, Planet Draft | Ops can view a log in Europa; user info; date/time; exactly which types were granted; to whom; Event Type `CLIENT_ACCESS_UPDATED`; Resource Type Contact; path format |
| `04-access-manager-revoke-selection.png` | The Access Manager with DepoView turned off, just before Save | Revoking access action taken |
| `05-europa-revoke-row.png` | Europa: the revoke row (**Access revoked:** MP4 Video › DepoView) above the grant row | Exactly which types were revoked; path format |
| `06-event-type-dropdown.png` | The Event Type dropdown open, listing `CLIENT_ACCESS_UPDATED` | Event type added to the Event Type drop down |
| `07-resource-type-dropdown.png` | The Resource Type dropdown open, listing `CONTACT` | Resource type added to the resource type dropdown |
| `08-europa-filter-resource-contact.png` | Europa filtered to Resource Type `CONTACT`: the two client access rows | Resource Type Contact filter |
| `09-access-manager-context-and-current-grant.png` | The overlay's Contact and Access to section (Case, Job number, Proceeding) with Planet Draft on, and Save disabled with nothing changed | Path values match the overlay; a save that changes nothing sends no record (V-09) |

**PR evidence (minimum set, 2026-10-13):** `07-resource-type-dropdown.png` and `06-event-type-dropdown.png` together cover every acceptance criterion.
- 07 shows both client access rows in full below the Resource Type menu, and the menu lists `CONTACT`.
- 06 shows `CLIENT_ACCESS_UPDATED` in the Event Type menu.

They are referenced from callisto-back-end #481 (07) and atlas-front-end #601 (06, 07).

## Not shown in a screenshot

- **Quoting a custom collection name containing `,` or `›`** (LD-018). This would need a new dynamic collection created on the proceeding. It is covered by callisto `contact-access-to-audit-event.assembler.spec.ts` (T13).
- **A no-change save through the API** (V-09). The UI blocks it (step 6). It is covered by callisto `contacts.service.spec.ts` (T7).
- **A missing contact or proceeding aborting the save** (V-11). It is covered by the callisto transaction-script spec (T5).

## State left behind

- **Test data:** one grant, contact 800002 on proceeding 3001, deliverable type Planet Draft (track-level), in local `callisto.deliverable_access_grants`. To undo, remove access in the UI (Client access → row menu → Remove access), or delete that row.
- **Europa:** two `CLIENT_ACCESS_UPDATED` records, at 15:42:50Z and 15:43:03Z.
- **Checkouts:** callisto-back-end and atlas-front-end stay on `INT-142`, and europa-back-end on `main`. Callisto's earlier lockfile change is in `stash@{0}` ("Before INT-142 test checkout 2026-10-13: …").
- **Scripts:** the Playwright scripts used for this run are in the session scratchpad (`e2e/int142-e2e.mjs`, `e2e/int142-e2e-nochange.mjs`); they are not part of the repo.
