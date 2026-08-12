# Job Story 01 — Copy task links in any context

| Field | Value |
| --- | --- |
| Ticket | enable-copy-links-page-view |
| Project | ClickUpWideLayout |
| Date | 2026-08-11 |
| Status | accepted |
| Source | [original-ticket.md](../original-ticket.md) |

## Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | A ClickUp user doesn't want copying task links to depend on opening a sidebar or popout pane. |
| Context + Intent | *While [context], they want to [action].* | While viewing a task on its full ClickUp page, they want to copy its title and Markdown link. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the current copy action only reads pane-bound metadata, so they want the same task link data available from the page header. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to copy either link format from the full page or a pane. |

## Revision Matrix

| Component | Before | Named issue | After |
| --- | --- | --- | --- |
| Motivation | A ClickUp user doesn't want copying task links to depend on opening a sidebar or popout pane. | Solution-speak — names sidebar, popout, and pane structures. | A ClickUp user doesn't want copying task links to depend on how they opened the task. |
| Context + Intent | While viewing a task on its full ClickUp page, they want to copy its title and Markdown link. | Solution-speak — names a page and view. | While looking at a task, they want to grab its title-based text and Markdown-formatted link. |
| Obstacle + Desired Action | Except that the current copy action only reads pane-bound metadata, so they want the same task link data available from the page header. | Solution-speak — describes the current component and header design. | Except that one way of opening the task does not expose those values, so they want them available wherever the task is open. |
| Resolution | Now they'll be able to copy either link format from the full page or a pane. | Solution-speak — names page and pane structures. | Now they'll be able to copy either format from a directly opened task or an overlaid task. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- A user who opens a task at its own ClickUp URL can copy the task's title-based link value without opening the task another way.
- A user who opens a task at its own ClickUp URL can copy the task's Markdown-formatted link without opening the task another way.
- Each copied value identifies the task currently being looked at and includes its URL when the selected format requires one.
- The existing title-based and Markdown-formatted copy outcomes remain available when the task is opened as an overlay.
- A user can start either copy outcome while looking at the directly opened task without switching context.

## Concatenated Story

A ClickUp user doesn't want copying task links to depend on how they opened the task. While looking at a task, they want to grab its title-based text and Markdown-formatted link. Except that one way of opening the task does not expose those values, so they want them available wherever the task is open. Now they'll be able to copy either format from a directly opened task or an overlaid task.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A ClickUp user doesn't want copying task links to depend on how they opened the task. | No issue — specific motivation with an observable dependency. | A ClickUp user doesn't want copying task links to depend on how they opened the task. |
| While looking at a task, they want to grab its title-based text and Markdown-formatted link. | No issue — everyday phrasing and concrete outcomes. | While looking at a task, they want to grab its title-based text and Markdown-formatted link. |
| Except that one way of opening the task does not expose those values, so they want them available wherever the task is open. | Wordiness — shorten the obstacle while retaining the desired outcome. | Except that one opening method hides those values, so they want access without changing context. |
| Now they'll be able to copy either format from a directly opened task or an overlaid task. | No issue — the result can be checked in both task contexts. | Now they'll be able to copy either format from a directly opened task or an overlaid task. |
| A user who opens a task at its own ClickUp URL can copy the task's title-based link value without opening the task another way. | Wordiness — remove repeated task phrasing. | From a task's own ClickUp URL, a user can copy its title-based link value without reopening it. |
| A user who opens a task at its own ClickUp URL can copy the task's Markdown-formatted link without opening the task another way. | Wordiness — remove repeated task phrasing. | From a task's own ClickUp URL, a user can copy its Markdown-formatted link without reopening it. |
| Each copied value identifies the task currently being looked at and includes its URL when the selected format requires one. | No issue — the payload can be compared with the active task. | Each copied value identifies the active task and includes its URL when the format requires one. |
| The existing title-based and Markdown-formatted copy outcomes remain available when the task is opened as an overlay. | Wordiness — simplify without losing the regression boundary. | Both existing copy outcomes remain available when the task opens as an overlay. |
| A user can start either copy outcome while looking at the directly opened task without switching context. | No issue — the action and no-context-switch outcome are observable. | A user can start either copy outcome from the directly opened task without switching context. |

## User Story

A ClickUp user doesn't want copying task links to depend on how they opened the task. While looking at a task, they want to grab its title-based text and Markdown-formatted link. Except that one opening method hides those values, so they want access without changing context. Now they'll be able to copy either format from a directly opened task or an overlaid task.

## Acceptance Criteria

- From a task's own ClickUp URL, a user can copy its title-based link value without reopening it.
- From a task's own ClickUp URL, a user can copy its Markdown-formatted link without reopening it.
- Each copied value identifies the active task and includes its URL when the format requires one.
- Both existing copy outcomes remain available when the task opens as an overlay.
- A user can start either copy outcome from the directly opened task without switching context.

## Open Questions

None. Phase 1 resolved the original questions from source and user evidence:

- “Title link” preserves the existing `ID - title` plus task URL payload; Markdown preserves `# [title - ID](url)`.
- Supported contexts are the directly opened full-screen task route and the existing pane/sidebar task variants.
- Unavailable or still-loading metadata preserves the established bounded retry followed by visible error feedback; it must not copy an unrelated URL.

## Story log

- **2026-08-11 — Phase 3:** Accepted without changing the five observable criteria. The locked-decision ledger formalizes existing-controls-only UI, content-owned context resolution, exact payloads, bounded failure behavior, and the no-backend boundary.
- **2026-08-11 — Phase 1:** Resolved all three open questions from code, live full-screen DOM evidence, and user clarification. Kept the five criteria unchanged and retained one story: the user locked the existing two popup controls as the only UI surface, while context-aware metadata resolution supplies both formats.
- **2026-08-11 — Phase 0:** Drafted the initial story, five acceptance criteria, and three open questions from the verbatim request before investigation.
