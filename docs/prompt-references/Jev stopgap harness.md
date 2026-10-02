# Jev at the stopgaps

How the implementer, the reviewer and Jev fit together across one ticket. Companion to `Implementation Instructions.md` and `Review Instructions.md`; the lifecycle table and the block consolidation come from their `- suggestions.md` files.

---

## 1. The three seats

| Seat | What it is | What it produces | What it never does |
| --- | --- | --- | --- |
| Implementer | A language model in its own harness (e.g. Opus) | Ledger, spec, code, screenshots, evidence per finding | Review its own work |
| Reviewer | A different language model in its own harness (e.g. Codex) | Numbered findings, each citing the ticket, spec or A/C line it violates | Edit anything |
| Jev | TypeSafe AI's System One model, called by the harness at every `---` | Typed answers with probabilities: is the stop clean, and which block fires next | Write text, findings or instructions |
| Person | You | The decisions Jev escalates, and the threshold Jev works to | Read stops Jev was confident about |

The implementer and reviewer are different models on purpose. A model reviewing its own output shares its blind spots. Jev is not a third opinion on content; it encodes the routing decision you would make at the stop, and hands you only the cases it cannot call.

---

## 2. What Jev is, as far as it matters here

Facts from the sources at the end. Anything not listed here is not assumed.

- **Input:** a `state` (text or structured data) and a map of typed `questions`. Output: one typed answer per question, each with a probability. No text.
- **Three question types.** `noul`: a statement, returns the probability it is true. `choice`: one of a listed set, returns a probability per option plus an overall confidence. `score`: ordered levels, returns a continuous value plus confidence.
- **Parallel.** Every question in a request is evaluated at once. Adding a question adds only its tokens.
- **Latency.** TypeSafe reports 70 to 500 ms end to end; commentary settles on about 100 ms per call. A chain five requests deep completes in well under a second.
- **Cost.** $0.042 per million input tokens, output free. Cost is not the constraint. Latency is what makes a chain of requests usable as one decision.
- **Literal.** It reads instructions as written. One judgment per question; a question hiding three factors gets split into three and combined in code.
- **State slicing.** Accuracy falls as unrelated content is added. Each question gets the slice of state it needs, not the conversation.
- **Injection.** Structured output is not a defense. Falsified content in the state produces wrong, well-formed answers. The state at every stop here is text an agent wrote.

---

## 3. The board

Four blocks and a stop. Every `choice` question in this document picks from this set.

| Option | Block | Harness |
| --- | --- | --- |
| `step` | The next implementer step block: ledger, spec, implement, or test, in ticket order | Implementer |
| `findings` | The Findings block, with the surviving findings pasted in | Implementer |
| `review` | The single Review block, with the artifact pasted in | Reviewer |
| `refire` | The block that just ran, again | Whichever ran |
| `stop` | Nothing fires. The person reads the stop | Person |

---

## 4. How one stop runs

A stop is a chain of Jev requests. Each level's answers become part of the next level's state. The root question, which block fires, is asked last, after the assessment that informs it.

```
Level 0   Harness reads the artifact the block produced, plus the A/C and the ledger.
          Builds one state slice per question.
             │
Level 1   One request. All assessment nouls in parallel.           ~100 ms
             │
Level 2   Fan-out when the artifact is a list (findings, evidence rows).
          One request per item, all items in parallel.              ~100 ms
             │
Level 3   One request. State = the artifact summary + every answer
          from levels 1 and 2. Question: `next_block` (choice).      ~100 ms
             │
Route     confidence ≥ T_high  →  fire the chosen block
          confidence ≤ T_low   →  fire the fallback for that stop kind
          otherwise            →  stop, person reads levels 1–3
          any reserved noul above T_low → stop regardless
```

**Thresholds** `T_high` and `T_low` are yours. The published pattern is accept when confident, escalate when unsure, with the cutoffs chosen against a small validation set of stops you have already judged by hand. Start strict; loosen as the record shows Jev agreeing with you.

**Reserved nouls** always stop for the person whatever the route says: a disputed finding, a finding that reopens a decision you made, an open question the agent left. Those are the decisions the design keeps with you.

---

## 5. The three stop kinds

Thirteen fires per round, three kinds of stop. The kind is fixed by which block just ran.

| After this block ran | Stop kind | Fallback when confidence is low on `next_block` |
| --- | --- | --- |
| Any implementer step (ledger, spec, implement, test) | **A** | `stop` |
| Review | **B** | `stop` |
| Findings | **C** | `stop` |

### Stop A — after an implementer step

State: the artifact, the ticket's A/C, the ledger.

```
Level 1 ─┬─ covers_all_ac        noul  Every acceptance criterion in the ticket is addressed by the artifact.
         ├─ adds_beyond_ticket   noul  The artifact contains work not required by any A/C or recorded ledger decision.
         ├─ has_open_question    noul  The artifact contains a question the agent could not answer from the codebase.   ← reserved
         └─ gates_recorded       noul  (implement and test steps only) A gate table with exact commands and results is present.
             │
Level 3 ─── next_block           choice  review | refire | stop
```

Expected reading: `covers_all_ac` high and `adds_beyond_ticket` low → `review`. `covers_all_ac` low → `refire`. `has_open_question` high → `stop`, always.

### Stop B — after the Review block

State per finding: that finding, the ticket/spec/A/C line it cites, the ledger.

```
Level 2 (one request per finding) ─┬─ cites_source_line          noul   The finding names a specific ticket, spec or A/C line it says is violated.
                                   ├─ reopens_locked_decision    noul   The finding contradicts a ledger decision recorded as a user answer.   ← reserved
                                   ├─ impact                     score  low | medium | high — share of A/C that fail if the finding stands.
                                   └─ route                      choice findings | drop | stop
             │
Level 3 ─── next_block             choice  findings | step | stop
```

Expected reading: a finding with `cites_source_line` low → `drop`. `reopens_locked_decision` high → `stop`, always. Zero findings survive → `step`. Any survive → `findings`, carrying only the survivors.

### Stop C — after the Findings block

State per finding row: the row, its recorded evidence, the diff summary.

```
Level 2 (one request per row) ─┬─ evidence_present        noul  The resolution includes a file and line, a command with its output, or a screenshot path.
                               ├─ evidence_resolves       noul  The evidence shows the finding no longer holds.
                               ├─ disputed                noul  The agent states the finding conflicts with the ticket instead of fixing it.   ← reserved
                               └─ changed_beyond_finding  noul  The diff includes work this finding did not ask for.
             │
Level 3 ─── next_block           choice  review | findings | stop
```

Expected reading: every row `evidence_resolves` high → `review`, same artifact. Any row `evidence_present` low → `findings`, carrying the unresolved rows. `disputed` high anywhere → `stop`, always.

---

## 6. The lifecycle with Jev in place

The person fires the base prompt once. From there, Jev routes and the person reads only escalations.

| Fire | Harness | Block | Stop kind after |
| --- | --- | --- | --- |
| 1 | Implementer | Base prompt: "Review INT-138. We are going to do INT-139 now." | A |
| 2 | Implementer | Step: save the investigation in the decisions ledger | A |
| 3 | Reviewer | Review, with the ledger pasted in | B |
| 4 | Implementer | Findings | C |
| 5 | Implementer | Step: write the spec | A |
| 6 | Reviewer | Review, with the spec pasted in | B |
| 7 | Implementer | Findings | C |
| 8 | Implementer | Step: implement on INT-139 | A |
| 9 | Reviewer | Review, with the branch or diff pasted in | B |
| 10 | Implementer | Findings | C |
| 11 | Implementer | Step: test, Playwright, screenshots | A |
| 12 | Reviewer | Review, with the evidence folder pasted in | B |
| 13 | Implementer | Findings | C |
| — | Person | PR, merge, or another round | — |

Fires 4, 7, 10 and 13 are one block. Fires 3, 6, 9 and 12 are one block. A round on a clean ticket is thirteen fires and zero reads by the person until the end. A round with disputes stops at the dispute.

---

## 7. What the harness has to do

The smallest runner that closes the loop. Nothing here needs Jev to be more than it is.

1. **Know the board.** Four blocks as text, and which harness each goes to.
2. **Read the artifact.** After a block finishes, load the artifact from the ticket folder. For lists, split into items.
3. **Slice the state.** Per question, assemble only the artifact slice, the A/C and the ledger lines that question needs.
4. **Call Jev in levels.** Level 1 assessment, level 2 fan-out, level 3 route. Carry answers forward as state.
5. **Apply the thresholds.** `T_high`, `T_low`, and the reserved nouls. Record every answer with its probability against the fire number.
6. **Fire or stop.** Paste the block, with its payload, into the target harness; or present the person with levels 1 to 3 and wait.
7. **Keep the record.** One row per stop: fire number, stop kind, every answer, the route taken, and whether the person overrode it. This is the validation set that tunes the thresholds later.

---

## 8. Risks that stay with the design

- **The state is agent-written.** An implementer's evidence, or a reviewer's finding, is the text Jev classifies. Falsified evidence produces a confident wrong route. The second model and the reserved stops are the check; Jev is not.
- **Jev picks from what you listed.** The board and the nouls are the intelligence. A route you did not list cannot be chosen. A factor you did not ask about is not weighed.
- **Thresholds are guesses until the record exists.** Run strict, read the escalations, and lower the bar only where the record shows agreement.
- **Reviewer output shape is the one contract.** Numbered findings, each with the line it violates. Without that, Stop B has nothing to slice per finding.

---

## Sources

- [Wikipedia: Jev (AI model)](https://en.wikipedia.org/wiki/Jev_(AI_model))
- [LangChain: Building a harness with Jev](https://www.langchain.com/blog/building-a-harness-with-jev)
- [width.ai: What Is Jev AI? TypeSafe's System One model](https://www.width.ai/post/what-is-jev-ai-typesafe)
- [6 Ways to Use Jev to Make AI Agents More Reliable](https://sarthakai.substack.com/p/6-ways-to-use-jev-to-make-ai-agents)
- [arXiv 2609.26550: JEV-as-a-Judge, Accept When Confident, Escalate When Unsure](https://arxiv.org/pdf/2609.26550)
- [Check Point: A decision model breaks like any other language model](https://blog.checkpoint.com/ai-security/jev-is-not-a-language-model-but-it-breaks-like-one-prompt-injection-against-a-typed-decision-model/)
- [heise: AI model Jev to make machines decide faster](https://www.heise.de/en/news/AI-model-Jev-to-make-machines-decide-faster-11457071.html)
