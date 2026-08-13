# W5 — Card workflow section fields — Spec

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `card-workflow-section-fields` |
| Body of work | W5 of [`003-agent-workflow-sync-work-breakdown.md`](../../../features/agent-workflow-sync/003-agent-workflow-sync-work-breakdown.md) |
| Governing decisions | [`001`](../../../features/agent-workflow-sync/001-agent-workflow-sync-decisions.md) → writing the four workflow values (D5, server-owned keys on the existing card patch), the API shape principle, and the additive-only constraint |
| Serves job story | [01 — Delegated work stays true](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-01-delegated-work-stays-true.md) |
| Depends on | none (deliberately — see *Why this does not use W1*) |
| Date | 2026-08-12 |

## Problem → Requirement → Solution

**Problem.** `Current Step`, `Waiting On`, `Next Up`, and `Work Ahead` exist nowhere in the codebase — they are a markdown convention inside `todo.text`. To set one, a caller must fetch the card, rewrite its whole body, and send it back. That puts the format convention in every caller, and the format is not uniform: 2 of 9 cards have only `Current Step`, and one puts its value on a bare line instead of a `-` bullet.

**Requirement.** Set any of the four values without disturbing the title, the `---` rule, or the sections not being written — and without the caller knowing the markdown convention.

**Solution.** A field-handler registry inside `updateTodo`: four new **optional** keys on the existing `PATCH /todos/:id`. A handler claims a key, performs the markdown surgery, and consumes the key so it is not spread onto the record as a stray property.

**No new route**, per the API shape principle and the user's explicit instruction (message 6): patch the card, do not invent `/todos/:id/sections`. The request body is the same body that will work in W9 when these values also land as real properties.

## Additive-only compliance

This is the one body of work that modifies an existing endpoint's handler, so the guarantee needs to be exact.

| Guarantee | How it is met |
| --- | --- |
| Existing keys behave identically | The registry runs only for keys it owns. `text`, `status`, `secondaryTagIds`, `tag`, `columnId`, `completed` and every other key take the exact path they take today |
| **With no new key present, the code path is unchanged** | The registry is a guarded branch: if none of the four keys appear in `updateData`, `updateTodo` executes its current body with no added work and no added allocation beyond one `Object.keys` check |
| Response shape unchanged | Still `{ message, todo }` |
| `dal.writeDB` still writes 12 sections | `updateTodo` keeps calling `writeDB`. The cascade via `touchColumnAndBoardForTodo` is preserved |
| No existing caller changes | `ApiService.updateTodo` and every UI call site are untouched |
| No route added or removed | `openapi.js` gains request-schema properties on an existing operation, not a new path |

### Why this does not use W1

W1's `patchRecord` would write one section instead of three. Using it here would mean repointing `updateTodo`'s write path, which the additive-only constraint forbids — existing callers of `PATCH /todos/:id` must keep the exact write behavior they have today.

So **card writes keep the twelve-section rewrite.** That is a conscious cost of the constraint, recorded in `001` → *What this constraint costs*. W5 has no dependency on W1 as a result.

### The precondition asymmetry — stated, not hidden

W4 makes `lastModified` **mandatory**, arguing that an optional precondition is not a precondition. That argument cannot be applied here: `PATCH /todos/:id` already has callers — the board UI — that send no `lastModified`. Requiring it would break them, which the constraint forbids.

So on this endpoint `lastModified` is **optional and honored when present**:

| Caller sends | Behavior |
| --- | --- |
| No `lastModified` | Current behavior exactly — last write wins, as today |
| `lastModified` matching stored | Applied; response carries the new value |
| `lastModified` not matching stored | `409` with the current value; nothing written |

**Residual risk:** a card-body collision between the agent and a human editing the card in read/write mode is still possible if the agent omits the precondition. The agent must always send it (W6 makes that normative). The risk is smaller than the note case — the card body is four short sections rather than a 35-item checklist — but it is not zero, and it is the constraint's cost rather than a solved problem.

## 1. Folder hierarchy

```text
WorkLists/
  dal.js                          field-handler registry + four handlers + markdown helpers
  openapi.js                      four request properties + the 409 response on an existing operation
  tests/
    card-section-fields.test.js   new
    api.test.js                   cases added
    openapi.test.js               cases added
```

No front-end file is modified. The card renders its body through the existing markdown path, so a written section appears with no UI work.

## 2. New functions

| Function | Purpose |
| --- | --- |
| `TODO_FIELD_HANDLERS` | The registry: key → handler. Four entries |
| `applyTodoFieldHandlers(todo, updateData)` | Runs matching handlers, returns the remaining keys to spread. Consumes claimed keys |
| `readWorkflowSection(text, heading)` | Parse a section's current value. Tolerates the bare-line variant |
| `writeWorkflowSection(text, heading, value)` | Replace or insert one section, preserving everything else byte-for-byte |
| `findWorkflowSectionInsertIndex(text, heading)` | Canonical-order insertion point for a missing section |

## 3. HTTP surface

**Existing operation, four new optional request properties. No new path.**

| Method | Path | New optional keys |
| --- | --- | --- |
| `PATCH` | `/todos/:id` | `currentStep`, `waitingOn`, `nextUp`, `workAhead`, plus optional `lastModified` |

### Request

```json
{
  "currentStep": "Investigation",
  "waitingOn": "",
  "nextUp": "Deploy to TST",
  "lastModified": "2026-08-11T16:11:43.705Z"
}
```

| Key | Type | Semantics |
| --- | --- | --- |
| `currentStep` | string | Replaces the `### Current Step` body |
| `waitingOn` | string | Replaces `### Waiting On`. Empty string clears to `- ` |
| `nextUp` | string | Replaces `### Next Up` |
| `workAhead` | string | Replaces `### Work Ahead` |

**Omitted key means "leave alone". Empty string means "clear".** These are different, and conflating them would make it impossible to clear a section.

`status` continues to ride in the same body through its existing validation, so a phase transition is one request. That is not new capability — `PATCH /todos/:id` already accepts `status` — it is simply what the agent will use instead of a second call to `/todos/:id/status`.

### Responses

| Status | When |
| --- | --- |
| `200` | `{ message, todo }` with the updated record |
| `400` | A section key present on a card with no workflow structure (see below); a non-string value |
| `404` | Unknown card id — existing behavior |
| `409` | `lastModified` present and stale |

## 4. Markdown surgery rules

Normative, because "preserve everything else" is the whole value of moving this server-side.

### Recognizing a workflow card

A card is a workflow card if its `text` contains at least one of the four `### ` headings. If a section key is sent to a card with none of them, respond **`400`** — do not scaffold.

**Why refuse rather than create.** Silently converting an arbitrary card into a workflow card is worse than failing: 36 of the 45 cards mentioning a ticket id are link stubs, release-tracking, or discussion cards, and a mistyped id would quietly restructure one of them. Structure is what identifies a workflow card (`001` → *Resolved: what counts as a workflow card*), so it must pre-exist.

### Replacing an existing section

| Input variant | Handling |
| --- | --- |
| `### Current Step\n- Investigation` | Bullet body replaced |
| `### Current Step\nQA` (bare line, `todo-1785246474470`) | Normalized to a `- ` bullet on write. The only case where the handler reformats rather than replaces, and it is confined to the section being written |
| `### Current Step\n- ` (empty) | Value inserted |
| Multi-line section body | **Entire** body between this heading and the next heading (or end of text) replaced |

### Inserting a missing section

Canonical order, matching every card that has all four:

```text
### Current Step
### Waiting On
### Next Up
### Work Ahead
```

A missing section is inserted at its canonical position relative to the sections that **are** present — after the last earlier one, or before the first later one. If none of the others are present the insert goes after the `---` rule, or after the H1 title when there is no rule.

### What must never change

- The H1 title line, including its link.
- The `---` separator.
- Any section not named in the request.
- Blank-line spacing between sections not being written.
- Any content after `### Work Ahead`.

**Byte-equality is the test.** For every section not named in the request, the before and after text must be byte-identical.

## 5. Modified entities

None. The four values live in `todo.text`, which already exists. **No new card property** — that is W9, and it is out of scope here.

## 6–8. Migrations, DTOs, projections

- **New migrations** — N/A. No stored shape changes; existing cards are readable and writable unchanged.
- **New DTOs** — request properties in §3, documented in `openapi.js`.
- **New projections** — N/A.

## Spec tests

### Happy path — `tests/card-section-fields.test.js`

| Scenario | Assertion |
| --- | --- |
| Set `currentStep` on a full four-section card | Only that section's body changes; **all other bytes identical** |
| Set three keys in one request | All three applied in one write |
| Clear `waitingOn` with `""` | Section body becomes `- ` |
| Omit `waitingOn` | Section untouched |
| Bare-line card (`todo-1785246474470` shape) | Normalized to a bullet; the rest of the card untouched |
| Card with only `### Current Step` — set `nextUp` | `Next Up` inserted after `Current Step`; `Waiting On` **not** created |
| Card with only `### Work Ahead` — set `currentStep` | `Current Step` inserted *before* `Work Ahead` |
| Multi-line section body | Whole body replaced |
| `status` in the same body | Applied through existing validation, same request |

### Failure paths

| Scenario | Assertion |
| --- | --- |
| Section key on a card with no `### ` headings | `400`; card byte-identical |
| Non-string value | `400`; card byte-identical |
| Invalid `status` alongside valid section keys | `400`; **no section applied** — atomicity |
| Stale `lastModified` | `409`; card byte-identical |
| Unknown card id | `404` |

### Additive-only regression — the critical set

| Scenario | Assertion |
| --- | --- |
| `PATCH /todos/:id { text }` | Behaves exactly as today, byte-identical result |
| `PATCH /todos/:id { status }` | Exactly as today, including validation errors |
| `PATCH /todos/:id { secondaryTagIds }` | Exactly as today |
| `PATCH /todos/:id { completed: true }` | Exactly as today |
| **No section key present** | `updateTodo` produces a result identical to the pre-change implementation, verified against a fixture captured before the change |
| Section keys are consumed | The saved record contains **no** `currentStep` property — it went into `text`, not onto the record |
| Timestamp cascade preserved | The card's column and its boards still get stamped |
| `writeDB` still writes 12 sections | Asserted, so this work is not mistaken for the deferred D0 fix |
| Full existing suite | Passes unchanged |

## Cross-cutting

- **Risk:** Medium — the only body of work touching a code path the UI uses daily. Mitigated by the guarded branch, the byte-equality assertions, and the pre-change fixture comparison.
- **Rollback:** Remove the registry, the handlers, and the OpenAPI properties. `updateTodo`'s original body is recoverable from the diff since nothing in it was rewritten.
- **Delivery order:** Fifth. No dependency on W1 or W3; could land any time after W2. W6 depends on it.
- **API docs:** **Required** — four request properties and the `409` on an existing operation. The `409` is new on this path and must be documented, not left implicit.
- **Authorization:** N/A.
- **Tooling gates:** `npm run lint`, `node --test`, `npm audit --audit-level=high`.

## Open questions and one gap

1. **Gap — nothing creates a workflow card's body scaffold.** W3 renders the checklist *note* from a template, but no body of work renders the card's four-section *body*. Since this spec refuses to scaffold and `POST /todos` is untouched, a new workflow card's structure still has to be created by hand. Options: extend W3's template to cover the card body too, or add a separate card-from-template route. **This should be resolved before W6, or the agent's first real run will hit a card the user had to hand-build anyway.**
2. **Should `currentStep` be validated against a vocabulary?** `001` resolved that it splits into a controlled value plus free detail — but that is W9. Here it is free text, matching today.
3. **Should the handler collapse a multi-line section to one line?** As specified it replaces the whole body with the single value, which loses multi-line content. Every observed card has a single-line body, so this matches reality — but it is destructive if a card ever has more.
