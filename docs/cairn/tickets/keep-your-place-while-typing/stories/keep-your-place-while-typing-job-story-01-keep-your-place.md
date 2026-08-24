# Job story 01 — They keep their place while they type

| Field | Value |
| --- | --- |
| Ticket | — (personal project, no ClickUp id) |
| Project | cairn (implementation: `PDProjects/Cairn`) |
| Drafted | 2026-08-24 |
| Status | **`draft`** |
| Source | [original-ticket.md](../original-ticket.md) — verbatim request only |
| User type | Someone keeping notes in their own vault |

Built from the verbatim request alone. Where the request leaves something undecided it is carried
below as an Open Question rather than settled by inference.

---

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | A note-keeper doesn't want to lose their place in the middle of writing a sentence. |
| Context + Intent | *While [context], they want to [action].* | While reading back through a note and spotting a word that is wrong, they want to fix it right where they see it. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the caret is reset to the start of the line when the projection re-renders after the debounced commit, so they want the caret offset preserved across the re-render. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to feel confident that the editor respects their cursor. |

## Revision Matrix

The story must be agnostic to system design. No design words — caret, projection, re-render,
commit, debounce, offset, block, editor, text box.

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| **Obstacle + Desired Action** (always revised) | Except that the caret is reset to the start of the line when the projection re-renders after the debounced commit, so they want the caret offset preserved across the re-render. | **Solution-speak** — "caret", "projection", "re-renders", "debounced commit" and "offset" all name system design, and the sentence describes *how the machinery misbehaves* rather than what the person is left unable to do. | Except that a moment after they stop typing they find themselves back at the start of the line, so they want to carry on from exactly where they were. |
| Resolution | Now they'll be able to feel confident that the editor respects their cursor. | **Emotional abstraction** — "feel confident" is not observable, and "the editor respects their cursor" names a component rather than an outcome. | Now they'll be able to type a whole sentence without stopping to find their place again. |
| Motivation | A note-keeper doesn't want to lose their place in the middle of writing a sentence. | *(no design words — unchanged)* | A note-keeper doesn't want to lose their place in the middle of writing a sentence. |
| Context + Intent | While reading back through a note and spotting a word that is wrong, they want to fix it right where they see it. | *(no design words — unchanged)* | While reading back through a note and spotting a word that is wrong, they want to fix it right where they see it. |

## Delivery Acceptance Statement (DAS)

> *We know this story is considered complete when:*
> - The cursor stays put while someone types.
> - Someone can type a whole sentence into a note in one go.
> - A person feels their place is being respected while they write.
> - Pausing partway through a word and picking it up again continues from the same spot.
> - When the note cannot take an edit, the person is told and is not moved somewhere else.
> - What they typed is in the file afterwards.

## Concatenated Story

A note-keeper doesn't want to lose their place in the middle of writing a sentence. While reading
back through a note and spotting a word that is wrong, they want to fix it right where they see it.
Except that a moment after they stop typing they find themselves back at the start of the line, so
they want to carry on from exactly where they were. Now they'll be able to type a whole sentence
without stopping to find their place again.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A note-keeper doesn't want to lose their place in the middle of writing a sentence. | None — one thought, observable, everyday register. | A note-keeper doesn't want to lose their place in the middle of writing a sentence. |
| While reading back through a note and spotting a word that is wrong, they want to fix it right where they see it. | None — "reading back", "spotting", "fix" are experiential, and "right where they see it" is the whole point of the surface. | While reading back through a note and spotting a word that is wrong, they want to fix it right where they see it. |
| Except that a moment after they stop typing they find themselves back at the start of the line, so they want to carry on from exactly where they were. | **Wordiness** — "find themselves back at" is three words doing one word's work. | Except that a moment after they stop typing they are back at the start of the line, so they want to carry on from where they were. |
| Now they'll be able to type a whole sentence without stopping to find their place again. | None — observable by anyone watching, and it is the thing that is currently impossible. | Now they'll be able to type a whole sentence without stopping to find their place again. |
| The cursor stays put while someone types. | **Non-observable outcome** — "stays put" cannot be checked, because the cursor is *supposed* to advance as characters are typed. What must not happen is it moving on its own. | The cursor only ever moves because the person moved it, by typing or by clicking. |
| Someone can type a whole sentence into a note in one go. | **Vague phrasing** — "in one go" does not say what would otherwise interrupt them. | Someone can type a sentence of at least a dozen words without the cursor leaving the end of what they typed. |
| A person feels their place is being respected while they write. | **Emotional abstraction** — "feels respected" cannot be confirmed by anyone. | Nothing in the note changes position while someone is typing in it. |
| Pausing partway through a word and picking it up again continues from the same spot. | **Vague phrasing** — "partway" and "the same spot" do not say for how long or where. | After pausing for several seconds mid-word, the next character typed lands immediately after the previous one. |
| When the note cannot take an edit, the person is told and is not moved somewhere else. | **Wordiness**, and "cannot take an edit" is vague about what the person sees. | When a change cannot be saved, the person is told so and their cursor stays where it was. |
| What they typed is in the file afterwards. | **Non-observable outcome** — "afterwards" does not say when, and "in the file" does not say the rest of the file is untouched. | Once saved, the note on disk contains what they typed and nothing else about the note has changed. |

## User Story

A note-keeper doesn't want to lose their place in the middle of writing a sentence. While reading
back through a note and spotting a word that is wrong, they want to fix it right where they see it.
Except that a moment after they stop typing they are back at the start of the line, so they want to
carry on from where they were. Now they'll be able to type a whole sentence without stopping to
find their place again.

## Acceptance Criteria

- The cursor only ever moves because the person moved it, by typing or by clicking.
- Someone can type a sentence of at least a dozen words without the cursor leaving the end of what
  they typed.
- Nothing in the note changes position while someone is typing in it.
- After pausing for several seconds mid-word, the next character typed lands immediately after the
  previous one.
- When a change cannot be saved, the person is told so and their cursor stays where it was.
- Once saved, the note on disk contains what they typed and nothing else about the note has
  changed.

## Open Questions

| # | Question | Why it is carried rather than answered |
| --- | --- | --- |
| `01.Q1` | When a change cannot be placed in the file, should what is on screen be put back to match the file, or should what the person typed stay visible while they are told it is unsaved? | The request says the cursor must not move; it does not say whether the typed words should survive a failure to save. The two behaviours are both defensible and the choice changes what the fifth criterion means. Not inferable from the request. |
| `01.Q2` | When the same words appear more than once on a line, is it acceptable for the app to decline the change and say so, rather than risk altering the wrong words? | The request does not address ambiguity. Declining is safe and visible; guessing is silent and could alter text the person was not editing. This needs a decision, not an assumption. |
| `01.Q3` | Does "keeping their place" extend across leaving the note and coming back to it, or only within a continuous stretch of typing? | Every report describes a single stretch of typing. Nothing in the request speaks to returning to a note later. |

## Story log

_Newest first. One entry per phase or session in which the story moved._

### 2026-08-24 — Drafted

- Written from the verbatim request in `original-ticket.md`. No investigation artifact existed.
- Motivation and user type taken from the request's own framing ("I want the editor to function
  like Word... I just want to start typing").
- Split considered and declined: the request also covers the editing surface itself keeping the
  document's shape, which is a distinct motivation and already behaves as asked. Only the
  place-keeping problem is drafted here, because that is the part being fixed. If the surface
  behaviour regresses, it is a new story rather than an amendment to this one.
- Three open questions carried. None resolved by inference.
