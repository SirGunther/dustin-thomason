# Job stories — WorkLists/attach-repository-files-as-notes

Source: [original-ticket.md](../original-ticket.md) · Decisions: [locked-decisions.md](../specs/attach-repository-files-as-notes-locked-decisions.md)

| # | Story | User type | Criteria | Open questions | Status | File |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | One permissioned folder | someone who keeps their documents in one folder | 5 | 0 | accepted | [file](./attach-repository-files-as-notes-job-story-01-one-permissioned-folder.md) |
| 02 | Pull in a document that already exists | someone who has already written a document | 9 | 0 | accepted | [file](./attach-repository-files-as-notes-job-story-02-pull-in-existing-document.md) |
| 03 | Edit the document where it lives | someone reading their own document beside their work | 6 | 0 | accepted | [file](./attach-repository-files-as-notes-job-story-03-edit-where-it-lives.md) |
| 04 | Take it off without losing the file | someone clearing out a finished piece of work | 6 | 0 | accepted | [file](./attach-repository-files-as-notes-job-story-04-take-it-off-without-losing-it.md) |
| 05 | One document, many places | someone whose one document matters to several pieces of work | 4 | 0 | accepted | [file](./attach-repository-files-as-notes-job-story-05-one-document-many-places.md) |
| 06 | See what is attached where | someone who keeps pulling the same documents into their work | 5 | 3 | **draft — out of scope for this slice** | [file](./attach-repository-files-as-notes-job-story-06-see-what-is-attached-where.md) |

Stories 01–05 are the deliverable. **Story 06 is not** — it is drafted so the idea survives, and left `draft` so nothing downstream mistakes it for accepted scope.

The request bundles five distinct problems, so it was split five ways. Stories 01 and 02 are the request's own two halves — designate the folder, then pull a document from it. Story 03 is the "edit" half of its closing requirement list and story 04 the "remove" half; they are separate because their failure modes differ entirely (a bad edit corrupts a real file, a bad removal destroys one). Story 05 is the request's "we can attach it to other places as well", which is distinct because it is the only one that constrains how a file is identified. Story 06 was surfaced by the owner at Phase 3 and is a sixth problem, not a sixth criterion.

A talking points list is available on request.

## Index log

- **2026-08-29 — Phase 5.** Story 02 reopened by the owner after seeing the built feature, and re-accepted with **three criteria added** (6 → 9): selecting several documents or a folder's worth at once, seeing and trimming the count before committing, and being told when part of a selection was skipped. Nothing was removed. Folder-selection is new scope; multi-select was a fair reading of the request's plural wording that the first implementation missed. Decisions LD-023 through LD-027.

- **2026-08-28 — Phase 3.** Stories 01–05 **accepted**; every open question closed (17 across the five — six by owner decision, eleven by evidence). Two criteria moved, both recorded rather than reinterpreted:
  - **Story 03** lost *"Nothing is written to the file until the person saves"* to LD-006 (autosave inherited). Replaced with a criterion that still forbids a read causing a write, which is what the original was protecting.
  - **Story 05** lost *"find out where else a document has been pulled in before they change or remove it"* to LD-008 — the owner rejected its premise, not its wording. **Story 06 created** to carry the useful requirement underneath it, reframed from a gate into an inventory.
  Criteria counts changed accordingly: 05 went from 5 to 4. Every other criterion is unchanged from its Phase 0 draft, which is the useful signal here — the criteria were written free of mechanism, so a mechanism decision that went against the request's own instruction (LD-001) landed without touching them.
- **2026-08-28 — Phase 1.** Every story revised in place (still `draft`). One question closed by evidence, four sharpened, one confirmed undecidable-from-code with proof. No criterion changed, no story split, no story superseded.
