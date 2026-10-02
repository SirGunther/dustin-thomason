# Review Instructions — suggestions

Companion to `Review Instructions.md`. The lifecycle of fires is in `Implementation Instructions - suggestions.md`.

The reviewer is a different model in a separate harness. It sees only what is pasted into its block. Its output goes back to a person, who carries it into the implementer's Findings block. That is the only contract between the two harnesses, and it is the one thing neither model can derive on its own.

---

## What exists and what is missing

| Fire | Block | Status |
| --- | --- | --- |
| 3 | Review the decisions in the ledger | Exists |
| 6 | Review the spec | Exists |
| 9 | Review the implementation | **Missing** |
| 12 | Review the evidence against the A/C | **Missing** |

The stated purpose of the reviewer is to determine whether the spec or the implementation is out of spec. The document covers the spec half only.

---

## Suggestions for this document

1. **Add an implementation block.** Same shape as the spec block. The paste slot takes the branch, worktree path or diff.

   ```markdown
   ### Implementation to Review


   #### Determine if the implementation:
   - matches the spec
   - follows the ticket
   - has scope creep
   - is overbuilt
   ```

2. **Add an evidence block.** The paste slot takes the screenshot folder.

   ```markdown
   ### Evidence to Review


   #### Determine if the evidence:
   - covers each A/C
   - shows what it claims to show
   ```

3. **State the output shape once.** The implementer's block says "for each finding". A prose verdict cannot be pasted into that. One sentence at the top of the document:

   > List each finding as a numbered item with the ticket, spec, or A/C line it violates.

4. **Typo.** "Ledge Location" → "Ledger Location".

5. **Not added.** Round caps, verdict words, permission rules, rewritten criteria. Termination and adjudication happen at the stop and are yours. The reviewer reads the four criteria as written.

---

## Replacement draft

```markdown
# Review Instructions

List each finding as a numbered item with the ticket, spec, or A/C line it violates.

### Original Ticket


### Ledger Location


Review the decisions made in the ledger

---

### Spec to Review


#### Determine if the spec:
- follows the ticket
- has scope creep
- is overbuilt
- is appropriate for the changes

---

### Implementation to Review


#### Determine if the implementation:
- matches the spec
- follows the ticket
- has scope creep
- is overbuilt

---

### Evidence to Review


#### Determine if the evidence:
- covers each A/C
- shows what it claims to show

---
```
