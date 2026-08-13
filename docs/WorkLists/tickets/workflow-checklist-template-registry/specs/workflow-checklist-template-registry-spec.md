# W3 — Card templates and the checklist format — Spec

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `workflow-checklist-template-registry` (folder kept; scope has grown twice — see *Scope history*) |
| Body of work | W3 of [`003` work breakdown](../../../features/agent-workflow-sync/003-agent-workflow-sync-work-breakdown.md) |
| Governing decisions | [`001` decision map](../../../features/agent-workflow-sync/001-agent-workflow-sync-decisions.md) → the checklist format is the contract (D3), template maintenance (D6), additive-only constraint |
| Serves job stories | [03 — The checklist stays mine to change](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-03-checklist-stays-mine-to-change.md), [05 — Tickets start pre-built](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-05-tickets-start-pre-built.md), [01](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-01-delegated-work-stays-true.md) |
| Depends on | none |
| Date | 2026-08-12 (second rewrite) |

## Scope history

Two rewrites, both narrowing then widening for good reasons:

1. **Was:** a template registry owning checklist identity — immutable per-item ids, versions, deprecation records, positional addressing, a drift check refusing hand-edited notes. **Removed** because the format is the contract, not the template.
2. **Now:** the format spec and parser (unchanged from rewrite 1) **plus a first-class Card Templates feature** — a template defines a whole ticket: its card body and its notes. Added on the user's direction, and it **replaces the duplicate-a-card mechanism** that W2 previously used to create a ticket's card.

Duplication returned the new card's id, which was the useful part. What it could not do was say what the shape *should* be — it copied whatever an existing card happened to have, drift included. A template says what the shape is.

## Problem → Requirement → Solution

**Problem.** Two problems, one feature.

- Nothing defines what a workflow *checklist* is, so nothing can read one reliably. Nine cards carry three heading generations and eight distinct item sets, grown 17 → 35 rows in six weeks.
- Nothing defines what a workflow *ticket* is. The card body — title, rule, four progress sections — and its checklist note get retyped or hand-copied every time, which is where that drift came from.

**Requirement.** A format that makes any conforming checklist readable, and one place to define what a new ticket starts with — its card body and its notes — editable where the app's other configuration lives, holding more than one definition so different work can start differently.

**Solution.** The checklist format plus a parser, and a `cardTemplates` data section with CRUD, a settings tab, a designated-template setting, and a creation route that emits a card and its notes and returns the new card's id.

## Part 1 — The checklist format

Unchanged from the previous rewrite. This is the contract: anything conforming is readable and writable, anything else is reported unrecognized.

```markdown
#### Section Heading
- [ ] An open step
- [x] A completed step
  - [ ] A nested step
  - A detail line that is not a step
```

| Element | Rule |
| --- | --- |
| **Section** | A heading line, three or four hashes. Its text is the section name |
| **Step** | A line with a task marker (unchecked or checked, case-insensitive). Text after the marker is the label |
| **Nesting** | Two-space indent, one level. A nested checkbox is a step; a nested plain bullet is a detail line |
| **Detail line** | An indented bullet with no checkbox. Free text — where `Approved by: Jerry B.` and `start testing on 08/12/26 @ 9 AM` live |
| **Anything else** | Preserved untouched. Prose, tables, code blocks all legal and ignored |

**A note is a checklist note** if it contains at least one section heading with at least one step under it. Deliberately permissive: prose alongside, extra sections, and hand-added steps are all still a checklist note.

**Addressing** is by section name plus step label as read in the same exchange — W4 owns that contract. Duplicate labels within one section make the pair ambiguous and are refused rather than guessed.

## Part 2 — Card Templates

### What a template holds

```json
[
  {
    "id": "card-template-ticket-workflow",
    "name": "Ticket Workflow",
    "description": "Standard PRDV ticket: progress sections plus the seven-phase checklist.",
    "cardText": "# [Title - PRDV-00000](https://app.clickup.com/t/43227262/PRDV-00000)\n---\n### Current Step\n- \n\n### Waiting On\n- \n\n### Next Up\n- \n\n### Work Ahead\n- ",
    "cardDefaults": { "tag": "Task", "status": "Unrefined" },
    "notes": [
      { "role": "primary", "name": "Workflow checklist", "text": "#### Preliminary\n- [ ] ..." },
      { "role": "secondary", "name": "Ticket description", "text": "# Ticket Description\n" }
    ],
    "createdAt": "2026-08-12T00:00:00.000Z",
    "lastModified": "2026-08-12T00:00:00.000Z"
  }
]
```

| Field | Rule |
| --- | --- |
| `cardText` | The card body, in the same markdown a card carries today. Must contain at least one of the four progress headings, so a template cannot produce a card W5 would then refuse |
| `cardDefaults` | Optional `tag` and `status` only. `status` validated against the statuses section at create time |
| `notes` | **Ordered list, any length.** `role` is `primary` or `secondary`, `name` is a human label, `text` is the note body |
| `notes[].text` | If a note's text parses as a checklist it will be readable by the agent; if not, it is an ordinary note. **Not validated as a checklist** — a template is allowed to carry prose notes, which the real cards already do |

**Why an ordered list rather than a fixed main-plus-secondaries pair.** The user described "main or secondary notes." An ordered list covers that and does not have to change when a template wants two prose notes or none. `role` records the intent; order records the sequence they get created in.

### Settings integration

A new tab in the existing settings dialog (`openModelSettingsDialog`, `public/todolist2.js:16262`), whose tab list today is General, Tag Colors, Secondary Tags, Statuses, Shortcuts, APIs, Prompts.

| Property | Value |
| --- | --- |
| Tab id | `card-templates` |
| Label | **Card Templates** |
| Icon | `fa-clipboard-list` |
| Position | After `Prompts` — both are "things that generate content", so they sit together |
| Panel contents | List of templates; create, rename, edit, delete; a markdown editor for `cardText` and each note; add/remove/reorder notes; and the designated-template selector below the list |

**Naming.** `Card Templates` is the recommendation, matching the flat literal naming of `Models`, `Statuses`, `Prompts`. `Ticket Templates` and `Card Blueprints` were the alternatives — recorded in story 05's open questions, decision is the user's.

### The designated template

A single setting naming which template the agent creates from. Stored in the templates section as a sibling record rather than a new section:

```json
{ "id": "card-template-settings", "designatedTemplateId": "card-template-ticket-workflow" }
```

**Why a setting rather than letting the caller pass any template id.** The creation route accepts an explicit `templateId` too — the setting is the *default* the agent uses when it was not told one. Without it the agent would have to choose, and choosing by inspection is the same class of mistake as searching for the target card: it can pick wrong, and wrong here builds a ticket from the wrong shape.

### Creation

```text
POST /api/cards/from-template
{ templateId?: string, title?: string, columnId: string }
-> 201 { message, todo, notes, templateId }
```

| Behavior | Detail |
| --- | --- |
| `templateId` omitted | Uses the designated template. `400` if none is designated |
| `columnId` | **Required.** A card must land somewhere; there is no sensible default |
| `title` | Optional. When given, replaces the template's first line |
| Card created | Through the existing `dal.addTodo`, so column `taskIds`, timestamps, and id generation all behave exactly as they do for a hand-created card |
| Notes created | One per `notes` entry, in order, each with a fresh `noteId` bound to the new card |
| **Response** | Carries the new `todo` — **including its `id`** — which is what makes the agent's create-then-work path possible, and what satisfies story 05's last criterion |

**Emitting the id is the load-bearing part of this route.** A create that does not return the identity of what it created leaves the caller with no way to continue.

## Additive-only compliance

| Guarantee | How it is met |
| --- | --- |
| No existing record changes | No new properties on cards or notes |
| No existing section changes | `cardTemplates` is a new `SECTIONS` entry; the 12 existing sections keep their shape |
| `markdownRenderer.js` untouched | Nothing is embedded in note or card text |
| Note pane untouched | Templated notes are ordinary notes |
| Existing note and card routes untouched | `POST /todos` and `POST /api/notes` keep their exact contracts. Creation from a template is a separate new route that calls the same DAL functions |
| Settings dialog | One tab **appended**; the seven existing tabs keep their ids, labels, icons, and order |
| `dal.addTodo` reused, not modified | The new route calls it; it does not change |

**The `SECTIONS` addition** changes what `readDB` returns (one extra key) and `writeDB` writes (one extra file) — unavoidable for any new section, precedented by `classificationPrompts`, `statuses`, `statusVisibility`. `TEMP_FILE_PATTERN` must be extended or the new section's temp files are skipped by cleanup.

## 1. Folder hierarchy

```text
WorkLists/
  dal.js                                  additions
  server.js                               new routes
  openapi.js                              new paths + schemas
  data/
    cardTemplates.json                    runtime, gitignored
    cardTemplates.example.json            committed reference
  public/
    apiService.js                         helpers added
    todolist2.js                          one settings tab + panel
  tests/
    checklist-format.test.js              new — the parser
    card-templates.test.js                new — CRUD + creation
    api.test.js / openapi.test.js         cases added
```

## 2. New functions

| Function | Purpose |
| --- | --- |
| `parseChecklist(text)` | Note text → `{ sections: [{ name, steps: [{ label, checked, indent, details }] }], recognized }` |
| `findChecklistStep(parsed, section, label)` | Locate one step; report not-found and ambiguous distinctly |
| `isChecklistNote(text)` | At least one section with at least one step |
| `normalizeCardTemplateRecord(t, i)` | Canonical shape; validates `cardText` carries a progress heading |
| `ensureCardTemplateStore(db)` | Seed starter templates when empty; dedupe by id; ensure the settings record exists |
| `getCardTemplates()` / `getCardTemplateById(id)` | Reads |
| `createCardTemplate` / `updateCardTemplate` / `deleteCardTemplate` | CRUD |
| `getDesignatedCardTemplateId()` / `setDesignatedCardTemplateId(id)` | The setting |
| `createCardFromTemplate(templateId, { title, columnId })` | Creates the card and its notes; returns both |

`parseChecklist` is pure, synchronous, and has **no dependency on templates** — which is the point of format-as-contract.

## 3. HTTP surface

All new. No existing route modified.

| Method | Path | Purpose | Responses |
| --- | --- | --- | --- |
| `GET` | `/api/card-templates` | List | `200` |
| `POST` | `/api/card-templates` | Create | `201`, `400` |
| `GET` | `/api/card-templates/{templateId}` | Read one | `200`, `404` |
| `PATCH` | `/api/card-templates/{templateId}` | Update | `200`, `400`, `404` |
| `DELETE` | `/api/card-templates/{templateId}` | Remove | `204`, `404`, `409` if it is the designated one |
| `GET` | `/api/card-templates/designated` | Read the setting | `200` |
| `PUT` | `/api/card-templates/designated` | Set it | `200`, `404` |
| `POST` | `/api/cards/from-template` | Create a ticket | `201`, `400`, `404` |

Deleting the designated template returns `409` rather than silently leaving the setting dangling.

## 4. Modified entities

**None.** Cards and notes keep their exact current shapes.

## 5–8. Migrations, DTOs, projections

- **Migrations** — N/A. New section seeded by `initialize()`.
- **DTOs** — shapes in §3 and Part 2, documented in `openapi.js`.
- **Projections** — N/A.

## Seed data

Two templates, so the plural case is exercised from day one rather than assumed:

1. **Ticket Workflow** — the four progress sections, plus the current 35-row seven-section checklist from note `8f04f8a8` as the primary note.
2. **Investigation Spike** — the shorter shape from the spike cards, proving a differently-shaped checklist works end to end.

## Spec tests

### Checklist format — `tests/checklist-format.test.js`

| Scenario | Assertion |
| --- | --- |
| The real 35-row note | Seven sections; every step found with correct checked state |
| Three-hash and four-hash headings | Both recognized |
| Lowercase and uppercase checked markers | Both parsed as checked |
| Nested step / nested detail line | Step vs. detail distinguished correctly |
| Prose, table, fenced code block in a note | Preserved, ignored, no false steps |
| Note with headings but no steps | `recognized: false` |
| The older `### Next Steps` generation | Parses — the case the first design rejected |
| The bespoke `Action Items` note | Parses on its own terms |
| Duplicate labels in one section | Reported ambiguous, not resolved |

### Card templates — `tests/card-templates.test.js`

| Scenario | Assertion |
| --- | --- |
| Cold start | Both starter templates seeded; settings record present; one designated |
| CRUD | Standard, mirroring `classificationPrompts` |
| `cardText` with no progress heading | Rejected `400` — cannot create a card W5 would refuse |
| Invalid `status` in `cardDefaults` | Rejected `400` |
| Notes list order | Preserved on create and on read |
| Delete the designated template | `409`; nothing removed |
| Set designated to an unknown id | `404` |

### Creation from a template

| Scenario | Assertion |
| --- | --- |
| Create with an explicit `templateId` | Card created with the template's body; one note per entry, in order |
| Create with `templateId` omitted | Uses the designated template |
| No template designated and none given | `400` |
| `columnId` omitted | `400` |
| `title` given | First line replaced; the rest of the body byte-identical to the template |
| **Response** | Carries `todo.id`; that id resolves through `GET /todos/:id` |
| Card lands in the column | Column `taskIds` updated exactly as `POST /todos` would |
| Notes bound to the new card | Each `eventId` equals the new card id; each `noteId` fresh |
| Primary note parses as a checklist | `isChecklistNote` true for the Ticket Workflow template |
| Unknown `templateId` / `columnId` | `404` |

### Additive-only regression

| Scenario | Assertion |
| --- | --- |
| Full existing suite | Passes unchanged |
| `GET /data` | One additional key; every pre-existing key byte-identical |
| `POST /todos` and `POST /api/notes` | Contracts unchanged |
| Existing notes | Round-trip byte-identically |
| `markdownRenderer.js` | Not modified — asserted by diff |
| Settings dialog | Seven existing tabs keep ids, labels, icons, order; the eighth is appended |
| Temp-file cleanup | `TEMP_FILE_PATTERN` recognizes `cardTemplates` |

## Cross-cutting

- **Risk:** Medium, and now the largest of the seven — it adds a section, a settings tab with a markdown-editing panel, and a creation route. The parser half is low risk and independently testable; the settings panel is the biggest unknown.
- **Rollback:** Remove the section from `SECTIONS`, the routes, the tab, and the data file. Cards and notes created from templates are ordinary cards and notes needing no unwinding.
- **Delivery order:** Third. W4 depends on the parser; W2's create-a-ticket path depends on the creation route.
- **API docs:** **Required** — eight new paths plus schemas, with `openapi.test.js` coverage.
- **Authorization:** N/A.
- **Tooling gates:** `npm run lint`, `node --test`, `npm audit --audit-level=high`.

## Open questions

1. **The feature's name in the UI** — `Card Templates` recommended; the user is deciding. Carried on story 05.
2. **Is there an in-app "new ticket from template" action, or agent-only at first?** The user raised agent-only as acceptable to start. If agent-only, the settings tab still earns its place (it is where templates are authored), but story 05's last criterion is only exercised through the agent. Recommendation: ship the routes and the tab; add a board-level "New from template" action only if you want it.
3. **Should `cardText` be validated as containing all four progress sections, or just one?** Specified as at least one, matching the two live cards that carry only `### Current Step`. Stricter validation would reject a legitimate shape.
