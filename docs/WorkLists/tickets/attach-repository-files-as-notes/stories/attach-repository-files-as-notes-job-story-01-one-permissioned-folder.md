# Job story 01 — One permissioned folder

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `attach-repository-files-as-notes` |
| Date | 2026-08-28 |
| Status | accepted (Phase 3) |
| Source | [original-ticket.md](../original-ticket.md) |

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | A person who keeps their working documents in one place doesn't want to re-authorise access to that place every time they want to use one of those documents. |
| Context + Intent | *While [context], they want to [action].* | While first setting up the place they track their work, they want to point it at the folder their documents already live in. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that there is no settings field holding a repository path and no permission grant behind it, so they want to add a setting that stores the folder path and triggers the permission prompt. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to reach any document inside that folder from anywhere in their work without being asked for access again. |

## Revision Matrix

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that there is no settings field holding a repository path and no permission grant behind it, so they want to add a setting that stores the folder path and triggers the permission prompt. | Solution-speak — "settings field", "permission grant" and "prompt" are all design elements. | Except that nothing in their work knows where that folder is or is allowed to open it, so they want to name that folder once and allow access to it once. |
| Context + Intent | While first setting up the place they track their work, they want to point it at the folder their documents already live in. | Wordiness — "the place they track their work" is a circumlocution for a thing the person just calls their work. | While first setting up their work, they want to say which folder their documents already live in. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*
- A person can name the one folder their documents live in, and that choice is still in effect the next time they open their work.
- Access to that folder is allowed once and stays allowed until the person changes it or clears it.
- Every document inside that folder, however deeply nested, can be reached; nothing outside that folder can.
- When access has lapsed or the folder can no longer be found, the person is told so plainly and can point at it again without losing anything.
- Before any folder has been named, nothing offers to pull in a document, and the person can see why not.

## Concatenated Story

A person who keeps their working documents in one place doesn't want to re-authorise access to that place every time they want to use one of those documents. While first setting up their work, they want to say which folder their documents already live in. Except that nothing in their work knows where that folder is or is allowed to open it, so they want to name that folder once and allow access to it once. Now they'll be able to reach any document inside that folder from anywhere in their work without being asked for access again.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A person who keeps their working documents in one place doesn't want to re-authorise access to that place every time they want to use one of those documents. | Wordiness and formal register — "re-authorise access to that place". | Someone who keeps their documents in one folder doesn't want to be asked for permission again every time they grab one. |
| While first setting up their work, they want to say which folder their documents already live in. | None. | While first setting up their work, they want to say which folder their documents already live in. |
| Except that nothing in their work knows where that folder is or is allowed to open it, so they want to name that folder once and allow access to it once. | None. | Except that nothing in their work knows where that folder is or is allowed to open it, so they want to name that folder once and allow access to it once. |
| Now they'll be able to reach any document inside that folder from anywhere in their work without being asked for access again. | None. | Now they'll be able to reach any document inside that folder from anywhere in their work without being asked for access again. |
| A person can name the one folder their documents live in, and that choice is still in effect the next time they open their work. | None. | A person can name the one folder their documents live in, and that choice is still in effect the next time they open their work. |
| Access to that folder is allowed once and stays allowed until the person changes it or clears it. | None. | Access to that folder is allowed once and stays allowed until the person changes it or clears it. |
| Every document inside that folder, however deeply nested, can be reached; nothing outside that folder can. | None. | Every document inside that folder, however deeply nested, can be reached; nothing outside that folder can. |
| When access has lapsed or the folder can no longer be found, the person is told so plainly and can point at it again without losing anything. | None. | When access has lapsed or the folder can no longer be found, the person is told so plainly and can point at it again without losing anything. |
| Before any folder has been named, nothing offers to pull in a document, and the person can see why not. | Non-observable outcome — "can see why not" cannot be confirmed. | Before any folder has been named, nothing offers to pull in a document, and the person is told that naming a folder is what unlocks it. |

## User Story

Someone who keeps their documents in one folder doesn't want to be asked for permission again every time they grab one. While first setting up their work, they want to say which folder their documents already live in. Except that nothing in their work knows where that folder is or is allowed to open it, so they want to name that folder once and allow access to it once. Now they'll be able to reach any document inside that folder from anywhere in their work without being asked for access again.

## Acceptance Criteria

- A person can name the one folder their documents live in, and that choice is still in effect the next time they open their work.
- Access to that folder is allowed once and stays allowed until the person changes it or clears it.
- Every document inside that folder, however deeply nested, can be reached; nothing outside that folder can.
- When access has lapsed or the folder can no longer be found, the person is told so plainly and can point at it again without losing anything.
- Before any folder has been named, nothing offers to pull in a document, and the person is told that naming a folder is what unlocks it.

## Open Questions

1. Does "allowed once and stays allowed" have to survive a restart of the machine, or only a reload of the work? The request says the attachment is "perpetually saved" but says nothing about how long access itself lasts. **Sharpened at Phase 1:** the answer differs by mechanism. A server-configured root survives everything until changed; a browser folder grant must be re-confirmed with `queryPermission` on every reload and can lapse silently (Cairn `components/vault-source/sources.js:108`). This question is downstream of the mechanism decision, not independent of it.
2. Is the named folder one per person or one per machine? **Sharpened at Phase 1:** there is no existing multi-machine mechanism to inherit. The host-scoped data files (`data/boards-OfficeComputer1.json`, `data/boards-PDLP-D362HS3.json`) are referenced by nothing and no `os.hostname()` call exists in the app — recorded in `docs/WorkLists/tickets/onedrive-per-record-file-spike/specs/…-spec.md`. So this is a fresh decision, not a pattern to follow.
3. ~~Where does the folder choice belong?~~ **Closed at Phase 1 by evidence.** A tabbed Settings dialog already exists — `public/todolist2.js:16828` `openModelSettingsDialog`, with General / Tag Colors / Secondary Tags / Statuses / Shortcuts / APIs / Prompts / Card Templates. The choice belongs in a further tab there; no new surface is needed. The criterion is unaffected — it never named a place.
4. ~~Which documents inside the folder count?~~ **Closed at Phase 3** (LD-014): `.md` and `.mdc` only. The surface renders Markdown; nothing else has a rendering path.

**All open questions closed.** Q1 by LD-001 + LD-015 — under a server-resolved root there is no grant that can lapse, so "stays allowed" survives reload, restart, and everything short of the folder itself becoming unreadable (which is a named, visible state). Q2 by LD-015 — the setting lives in the OneDrive-synced `data/` tree so the value follows the person, and the chosen root `C:\dustin-thomason` is a git clone present on each machine, so the same absolute path resolves on both; a machine without the clone gets the visible unreadable-root state, not silence.

## Story log

- **2026-08-28 — Phase 3 — ACCEPTED.** All remaining questions closed (Q1, Q2 → LD-001/LD-015; Q4 → LD-014). **No criterion changed.** Worth recording that the criteria survived a mechanism decision that went the opposite way from the request's instruction — they were written free of any mechanism, which is exactly what let LD-001 land without touching them. One criterion is now *stronger* than drafted: "allowed once and stays allowed" has no lapse mode at all under a server root, where a browser grant would have had one. Status → `accepted`.
- **2026-08-28 — Phase 1.** Q3 **closed by evidence** (an existing Settings dialog with a tab structure). Q1 and Q2 **sharpened** with the evidence that bears on them; both remain genuine decisions. No criterion changed — the criteria were written free of any place or mechanism, and the evidence found nothing that invalidates one. Status stays `draft`: Q1 is now known to depend on the mechanism decision, which is unresolved.
- **2026-08-28 — Phase 0.** Drafted from the verbatim request. Open questions 1–4 are things the request left undecided; none were decided here.
