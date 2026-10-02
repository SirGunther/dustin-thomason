# Implementation Instructions — suggestions

Companion to `Implementation Instructions.md`.

The setup: two agents in separate harnesses. One model implements, a different model reviews, so the two do not share blind spots. A person sits at every `---`, reads the state, and fires the next block. A block carries the next step and the stop. Everything else the agent derives from the repo and the always-on rules.

The test for every suggestion below: does a harness need this and cannot derive it. Almost nothing passes. What does pass is the contract between the two harnesses, because neither model can know what the other's block expects.

---

## The lifecycle as fires

Fires 4, 7, 10 and 13 are the same block. Order and repetition are the person's call at each stop.

| Fire | Harness | Block fired | Person reads at the stop |
| --- | --- | --- | --- |
| 1 | Implementer | Base prompt: "Review INT-138. We are going to do INT-139 now." | The agent's understanding of the ticket |
| 2 | Implementer | Save the investigation in the decisions ledger | The ledger |
| 3 | Reviewer | Review the decisions in the ledger | Findings on the ledger |
| 4 | Implementer | Findings block, with fire 3's findings pasted in | Evidence per finding |
| 5 | Implementer | Write the spec | The spec |
| 6 | Reviewer | Review the spec | Findings on the spec |
| 7 | Implementer | Findings block, with fire 6's findings pasted in | Evidence per finding |
| 8 | Implementer | Implement on INT-139 | Diffs, branch state |
| 9 | Reviewer | Review the implementation. **No block exists today.** | Findings on the code |
| 10 | Implementer | Findings block | Evidence per finding |
| 11 | Implementer | Test, Playwright, screenshots | Screenshots |
| 12 | Reviewer | Review the evidence against the A/C. **No block exists today.** | Findings on the evidence |
| 13 | Implementer | Findings block | Evidence per finding |
| — | Person | PR, merge, or another round | — |

The two missing reviewer blocks are in `Review Instructions - suggestions.md`.

---

## Suggestions for this document

1. **Findings block: add a paste slot.** The reviewer's output is in another harness. The person, or a harness such as JEV, carries it. Give the block a heading with blank lines under it, the same shape the Review doc already uses for `### Original Ticket`.

   ```markdown
   ### Findings


   For each finding, this is the process: ...
   ```

2. **Findings block: one line for disagreement.** A finding arrives with the reviewer's authority and the reviewer's blind spot. The ticket is already the source of truth, but the block does not say what to do when the two conflict.

   > If a finding conflicts with the Original Ticket or A/C, say so with the line it conflicts with, and do not implement it.

   The person sees the dispute at the stop and decides. Nothing is agreed between the two models without you.

3. **Typo.** "decisions ledged" → "decisions ledger".

4. **Nothing else.** Worktrees, subagents, gates, Playwright, screenshot placement, base branch: the agent derives how from the repo, the ticket folder and the always-on rules. The findings block sitting first in the file is correct, since it is the block fired most often.
