# W4 — Note checklist patch and concurrency — Spec

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `note-checklist-patch-and-concurrency` |
| Body of work | W4 of [`003` work breakdown](../../../features/agent-workflow-sync/003-agent-workflow-sync-work-breakdown.md) |
| Governing decisions | [`001` decision map](../../../features/agent-workflow-sync/001-agent-workflow-sync-decisions.md) → write safety (D4), API shape principle, additive-only constraint |
| Serves job stories | [04 — Nothing I typed disappears](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-04-nothing-i-typed-disappears.md), [01](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-01-delegated-work-stays-true.md) |
| Depends on | W1 (record access), W3 (`parseChecklist`, `findChecklistStep`) |
| Date | 2026-08-12 (addressing model rewritten) |

## Rewritten — what changed and why

This spec previously addressed checklist steps by **template item id**, with a version pin and a drift check that refused any hand-edited note. The template no longer owns identity — the format does (see W3's rewrite).

**New addressing model: section name + step label, as read in the same exchange.**

The objection to matching on text was that wording drifts. That objection does not apply here, and the reason is the precondition:

> The caller reads the note, sees the current labels, and sends those exact labels back **together with the `lastModified` it just read**. If anything about the note changed in between, the write is rejected outright. So the text being matched cannot be stale — a stale note fails the precondition before any matching happens.

Text matching is unsafe when the text is remembered. It is safe when the text was just read and the read is verified. That is the whole difference, and it is why the precondition is mandatory rather than optional on this endpoint.

| Dropped | Replaced by |
| --- | --- |
| Template item ids in the request | Section name + step label |
| Version pinning | The `lastModified` precondition |
| The strict drift check | Nothing — a hand-edited checklist is still a valid checklist |
| `422` for "not trackable" | `422` only when the note has no recognizable checklist structure at all |

## Problem → Requirement → Solution

**Problem.** `PUT /api/notes/:noteId` replaces the entire note body and takes no precondition. An agent write and a human edit collide silently — whichever saves last wins, and neither party is told. There is also no way to change one checklist step; the only write is a whole-text replacement.

**Requirement.** Mark specific checklist steps without sending the whole note body, and never silently discard a concurrent human edit.

**Solution.** Add `PATCH /api/notes/:noteId` taking step changes addressed by section and label, with a mandatory `lastModified` precondition. Leave the existing `PUT` exactly as it is.

## Additive-only compliance

| Guarantee | How it is met |
| --- | --- |
| `PUT /api/notes/:noteId` unchanged | Not modified. Still replaces `text`, still takes no precondition. `ApiService.updateNote` untouched |
| `GET`/`POST`/`DELETE /api/notes` unchanged | Not modified |
| `dal.writeNotes` unchanged | `PUT` continues to use it, still rewriting all sections |
| Note pane unchanged | No front-end file modified by this work |
| No note property changes | Nothing added to the note record — W3's rewrite removed the only properties proposed |

A new verb on an existing path is additive: existing verbs keep their exact behavior. The note pane keeps using `PUT`; this `PATCH` exists for the agent.

## 1. Folder hierarchy

```text
WorkLists/
  dal.js                     one function added
  server.js                  one route added
  openapi.js                 one operation + schemas added
  public/apiService.js       one helper added (not consumed by the UI)
  tests/
    note-checklist-patch.test.js   new
    api.test.js                    cases added
    openapi.test.js                cases added
```

## 2. New functions

| Function | File | Purpose |
| --- | --- | --- |
| `patchNoteChecklistSteps(noteId, steps, options)` | `dal.js` | Parse the note, locate each step, apply checked state and detail values, write via record access |
| route handler for `PATCH /api/notes/:noteId` | `server.js` | Validate, call the DAL, map errors through the existing `sendDalError` |
| `ApiService.patchNoteChecklistSteps(noteId, payload)` | `public/apiService.js` | Fetch helper |

## 3. HTTP surface

**New verb on an existing path. The existing `PUT` on that path is untouched.**

### Request

```json
{
  "lastModified": "2026-08-11T16:05:00.513Z",
  "steps": [
    { "section": "Preliminary", "label": "copy spec", "checked": true },
    {
      "section": "Testing & Validation",
      "label": "Test and validate implementation locally",
      "checked": true,
      "details": [
        { "match": "start testing", "value": "start testing on 08/12/26 @ 9 AM" },
        { "match": "finished testing", "value": "finished testing on 08/12/26 @ 2 PM" }
      ]
    }
  ]
}
```

| Field | Required | Rule |
| --- | --- | --- |
| `lastModified` | **Yes** | The value the caller just read. Absent → `400`, never a silent bypass |
| `steps` | Yes | Non-empty. A whole phase's changes ride in one request |
| `steps[].section` | Yes | Section name as read. Matched exactly after trimming |
| `steps[].label` | Yes | Step label as read. Matched exactly after trimming |
| `steps[].checked` | No | Boolean. Omitted leaves the current state |
| `steps[].details[].match` | No | A substring identifying which detail line under that step to replace |
| `steps[].details[].value` | No | The replacement text for that detail line |

**Matching is exact after trimming, not fuzzy.** No normalization, no case-folding, no token overlap. The caller read the label moments ago and the precondition proves the note has not moved; an exact match is therefore achievable and anything looser only creates room for the wrong row to be hit.

**Detail lines use substring `match` rather than exact text**, because their current content is a placeholder being replaced (`start testing on date @ time` → a real timestamp). An exact match would require echoing the placeholder, and a placeholder that has already been filled once would then fail. A `match` that hits more than one detail line under that step is refused as ambiguous.

### Responses

| Status | When | Body |
| --- | --- | --- |
| `200` | Applied | `{ message, note }` — `note.lastModified` is the new value |
| `400` | Malformed body, missing `lastModified`, empty `steps`, section not found, label not found, ambiguous label, ambiguous detail `match` | `{ message }` naming what failed |
| `404` | No note with that `noteId` | `{ message }` |
| `409` | `lastModified` does not match stored | `{ message, lastModified }` — the current value |
| `422` | The note has no recognizable checklist structure | `{ message }` |

**`422` is now narrow.** It fires only when `parseChecklist` returns `recognized: false` — no section with any step. A hand-edited, reordered, or non-standard checklist is *not* a `422`; it parses and is writable. The earlier design refused those, which was the over-scoping this rewrite removes.

**Not-found is `400`, not `404`.** A missing section or label means the caller's view of the note was wrong, which is a bad request against a note that exists. `404` stays reserved for the note itself.

### Atomicity

**All steps apply or none do.** Every section, label, and detail `match` is resolved before any mutation. One failure fails the whole request and writes nothing — a partial application would leave a state neither party intended, with no way for the caller to tell which half landed.

## 4. Modified entities

None. `lastModified` already exists on every note and is already stamped by `ensureLastModified`.

## 5–8. Migrations, DTOs, projections

- **Migrations** — N/A.
- **DTOs** — shapes in §3, documented in `openapi.js`.
- **Projections** — N/A.

## Write mechanics

1. Read the note through record access, under one lock acquisition.
2. Compare stored `lastModified` to the request's. Mismatch → `409`, nothing written.
3. `parseChecklist(note.text)`. Not recognized → `422`.
4. Resolve every step and detail. Any failure → `400`, nothing written.
5. Apply changes **line by line to the original text**, not by re-serializing the parse. Only the checkbox character and the named detail lines change; every other byte is preserved.
6. Stamp a new `lastModified`, write the notes section only, return the record.

**Step 5 is normative.** Re-rendering the note from the parsed structure would silently reformat the user's prose, spacing, tables, and anything the parser ignored. The parse is used to *locate*, never to rewrite.

## Spec tests

### Happy path

| Scenario | Assertion |
| --- | --- |
| One step checked | `200`; only that line's checkbox character changes; **every other byte identical** |
| Eight steps in one request | All applied in one write |
| Step unchecked | Checkbox cleared |
| Detail line filled by substring match | That line's text replaced; siblings untouched |
| Detail filled twice (placeholder, then a real value) | Second call succeeds — the `match` still hits |
| Nested step | Resolves and toggles |
| Note containing prose, a table, and a code block | Checklist updated; the rest byte-identical |
| A hand-edited checklist with an extra step | **Writable** — the case the earlier design rejected |
| An older-generation checklist (`### Next Steps`) | Writable |
| Response `lastModified` | Newer than the request's, equal to stored |

### Failure paths

| Scenario | Assertion |
| --- | --- |
| `lastModified` omitted | `400`; nothing written |
| Stale `lastModified` | `409` carrying the current value; note byte-identical |
| Unknown `noteId` | `404` |
| Unknown section | `400`; nothing written |
| Unknown label in a known section | `400`; nothing written |
| Duplicate label within a section | `400` ambiguous; nothing written |
| Detail `match` hitting two lines | `400` ambiguous; nothing written |
| One bad step among seven good ones | `400`; **none of the seven applied** |
| Note with no checklist structure | `422` |
| Empty `steps` | `400` |

### Concurrency — the core of job story 04

| Scenario | Assertion |
| --- | --- |
| Read, human `PUT` changes the note, agent `PATCH` with the pre-`PUT` value | `409`; the human's text survives intact |
| Two `PATCH` calls with the same original `lastModified` | Second gets `409` — proves the value advances |
| `PATCH` concurrent with a whole-database write | Both land; neither lost |
| Section isolation | Writes the notes section only; other section files byte-identical, mtimes unchanged |

### Additive-only regression

| Scenario | Assertion |
| --- | --- |
| Full existing suite | Passes unchanged |
| `PUT /api/notes/:noteId` | Still a whole-text replace with no precondition — asserted explicitly so a future refactor cannot add one to the path the UI uses |
| Note pane | `tests/browser-notes-smoke.js`, `tests/notes-collapse.test.js` pass unchanged |
| `POST`/`GET`/`DELETE /api/notes` | Contracts unchanged |

## Cross-cutting

- **Risk:** Low-to-medium. The route is new and the UI does not consume it. The sharp edge is `PUT` and `PATCH` coexisting on one path with different safety guarantees — deliberate, and documented in `openapi.js` so it is not read as an oversight.
- **Rollback:** Remove the route, DAL function, helper, and OpenAPI entries. `PUT` never changed.
- **Delivery order:** Fourth, after W1 and W3. W6 depends on it.
- **API docs:** **Required** — the operation, the `409` and `422` responses, and the request schema.
- **Authorization:** N/A.
- **Tooling gates:** `npm run lint`, `node --test`, `npm audit --audit-level=high`.

## Open questions

1. **May the agent uncheck a step?** The endpoint accepts `checked: false`. Whether the agent is *permitted* to send it is W6's decision. Flagged so the capability is a conscious choice rather than a side effect of the schema.
2. **Should `409` surface in the UI?** Only the agent calls this today, so a conflict reaches the user through the agent's report. If the note pane ever adopts `PATCH`, it needs its own conflict presentation.
3. **Should section matching tolerate heading-level differences?** A note using `###` where the caller read `####` still has the same section name. As specified, only the name is matched and the level is ignored — confirm that is intended.
