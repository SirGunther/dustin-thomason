# Original ticket — Keep your place while typing

| Field | Value |
| --- | --- |
| Project | cairn (implementation: `PDProjects/Cairn`) |
| Slug | `keep-your-place-while-typing` |
| Captured | 2026-08-24 |
| Source | User messages in session, verbatim |

## Original Request

Captured verbatim across the messages in which it was given. Nothing here is paraphrased,
reordered within a quote, or completed by inference.

On what the editing surface must be:

> I want the editor to function like Word, where the document remains in its state and I can
> simply go in and edit it. Nothing about the editing process should change the document
> structure. I just want to start typing. If I insert a header or a checklist item, the system
> should automatically interpret that formatting. For instance, if I go to a new line and type a
> bullet followed by a space, it should automatically render as a new bullet. The same should
> apply to numbers and code blocks. You have created a rigid framework where I am forced to edit
> within a text box.

On the defect, first report:

> When I went to the end of a file and hit enter twice, the cursor jumped back to the end of the
> last sentence. I hit enter a couple more times and started to type, but it jumped again. The
> first time it happened, it went to the very top of the entire document. Another time, it jumped
> to the prior paragraph. The cursor is moving around with really odd behavior. I cannot quite put
> my finger on what it is doing or why it is doing it, but this seems like another defect.

On the defect, second report:

> Anytime I do any sort of edit, the cursor jumps to the very start of the document a second after
> I stop typing.

On the defect, current report:

> The current defect is that whenever I start typing, the cursor jumps back to the start of the
> line. It does not go to the top of the document, but it consistently resets to the beginning of
> the line. At this point, the patches being applied are not resolving the issue.

## Provenance

- Reported by the user against the running application, served locally in Chromium.
- Three reports of the same class of symptom over three sessions, each with a different
  destination for the cursor: prior paragraph, top of document, start of line.
- No ClickUp ticket exists; this is a personal-project request.
