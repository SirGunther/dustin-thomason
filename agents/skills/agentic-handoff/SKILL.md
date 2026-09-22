---

# Agentic handoff

Build the documents an orchestrated, multi-agent piece of work runs on, in one parent folder. The orchestrating agent uses them to sequence, dispatch, test, merge, and audit the work. Each implementation agent receives one ticket and returns it with its evidence filled in.

Documents are identified by **role**, not filename. Names vary by setting — a company ticket, a meeting transcript, a chat request — so find or ask for the document that plays each role, and record its path once, in the handoff.

## Operational definitions

Every section of every document below carries an operational definition:

* **Contains** — what goes in it.
* **Excludes** — what must not, and where that content goes instead.
* **Written by** — which agent writes it, and when.
* **Done when** — the observable condition that makes the section complete.

A section is complete only when its **Done when** condition can be checked and holds. Content that fails a section's definition belongs in another section, or nowhere.

## Who writes what

* **Author** — the agent running this skill. Writes the foundation documents, the handoff, and the frame of every ticket.
* **Orchestrating agent** — dispatches tickets, reviews each result, merges, and records the audit. Often the same agent as the author.
* **Implementation agent** — receives one ticket, does the work, fills in that ticket's checkboxes and objectives, and returns its evidence.

**One writer per file at a time.** After dispatch, only the orchestrating agent writes the handoff, and only the assigned implementation agent writes its ticket's checkboxes and objectives. Parallel agents never write to the same file.

## The document set

| Role | Answers | Default name |
| --- | --- | --- |
| Origin | Why the work was asked for | `<id>-original-ticket.md` |
| Requirements | What must be true, and what exists that it depends on | — (provided) |
| Decisions | How the requirements will be met | `<id>-decisions.md` |
| Handoff | How the work is sequenced, dispatched, tested, merged, and audited | `<id>-handoff.md` |
| Ticket | One unit of work, and its evidence | `tickets/<TICKET-ID>.md` |

`<id>` is the origin's ticket id when it has one (e.g. `PRDV-16936`), otherwise the slug.

## Parent folder

All documents live in one folder. Resolve it in this order:

1. The folder the user names.
2. The folder that holds the origin document.
3. `C:\dustin-thomason\docs\<Project>\tickets\<slug>\` — the folder `orchestrate` and `job-story` use.

Never load or cite anything under a `dnu/` folder.

## 1. Origin — the why

* **Contains:** the request as it was given — a ticket export, a meeting transcript, a forwarded message. One or more documents.
* **Excludes:** findings, requirements, decisions, and links to anything downstream.
* **Written by:** whoever made the request. The author only captures pasted text, verbatim per `../orchestrate/docs/original-ticket-artifact.md`, before any other document. Never edited after capture.
* **Done when:** it exists in the parent folder, unchanged since capture.

If no origin document exists and none is pasted, stop and say exactly: "I don't have the source artifact needed to answer that accurately. Please paste it or point me to the file/location." (per the `source-truth` rule)

## 2. Requirements — the source of truth

What must be true, and the evidence of what exists that those requirements depend on. When another document disagrees with this one, this one holds until it is changed with a source.

It must be provided. If none exists, stop and ask the user where it is. The author fleshes it out: keep its wording and structure, add what is missing (including IDs on existing items), cite a source for every addition, and gather evidence yourself rather than asking the user for anything the code or documents can answer. A requirement you cannot source goes to chat as an open question, not into the document.

### Requirements (`REQ-###`)

* **Contains:** one condition that must be true per item, each citing where it came from — an origin passage, or a named person and date.
* **Excludes:** how the condition will be met (→ decisions) and facts about what exists (→ evidence).
* **Written by:** provided; the author adds IDs and sourced additions.
* **Done when:** every item has an ID and a source, and every item is served by at least one ticket.

### Evidence (`EV-###`)

* **Contains:** one fact about what exists per item — a field, column, label, route, or contract — quoted exactly, with a direct pointer (`path:line`, `path:symbol`, or URL).
* **Excludes:** interpretation and choices (→ decisions).
* **Written by:** the author, read directly from the source.
* **Done when:** every pointer resolves and every quote matches its source.

### Scope boundary

* **Contains:** what may change and what is read-only, by repo or path.
* **Excludes:** per-ticket file ownership (→ each ticket's header).
* **Written by:** provided, or added by the author with a source.
* **Done when:** every repo and path the work touches is named writable or read-only.

### Readiness

* **Contains:** each prerequisite, and whether it is met.
* **Excludes:** work still to be done (→ tickets).
* **Written by:** provided; the author updates status with evidence.
* **Done when:** every prerequisite is marked met, or unmet with its blocker named.

## 3. Decisions — the how

Use the `LD-###` series from `../../docs/qa-to-spec-traceability.md`, so a ledger produced there fills this role without renumbering:

```markdown
# <id> — Decisions

Requirements: [<requirements file>](./<requirements file>)

| ID | Decision | Why | Serves | Source | Supersedes or rejects |
| --- | --- | --- | --- | --- | --- |
| LD-001 | | | REQ-### | | |
```

* **Contains:** one choice per row about how the requirements will be met, with why, the requirements it serves, and its source. `Serves` is `—` for a decision about process rather than product.
* **Excludes:** facts about what exists (→ evidence), and any decision without a source.
* **Written by:** the author, only from sourced decisions — the user, an origin document, or a named participant. A decision you would recommend goes to chat as a question; it enters the ledger once the user confirms it, with that confirmation as its source.
* **Done when:** every row has a source, and every superseded row stays in place, marked, pointing at its replacement.

If a locked-decision ledger already exists in the parent folder or its `specs/`, it fills this role. Reference it from the handoff; do not copy it.

### Numbered open-decision register

The decisions document keeps a stable numbered register immediately after the locked-decision
ledger. This lets the user answer tersely in chat — for example, `1. local storage is fine` — without
losing which gap the answer resolves.

```markdown
## Open Decision Register

### 1. <decision question title>
**State:** Resolved | Unresolved
**Value:** <the exact open question, or `Resolved as LD-###`>
**Evidence:** <source pointer for the gap or resolution>
**Depends on:** <what is blocked, or —>
```

* **Contains:** every material decision question that is not answered by a source, numbered from `1`
  upward in discovery order. Resolved entries remain in place and point to the resulting `LD-###`
  row.
* **Excludes:** the decision's implementation-shaped value once resolved (→ locked-decision ledger),
  speculative recommendations, and non-blocking implementation details.
* **Written by:** the author adds unresolved entries. When the user answers one, the orchestrating
  agent adds the sourced `LD-###` row and changes that numbered entry to `Resolved as LD-###` in the
  same pass.
* **Done when:** every material gap is numbered; every resolved item points to its locked decision;
  every unresolved item names what it blocks.

Numbering rules:

* Never renumber, reorder, reuse, migrate, or delete an entry.
* A resolved entry stays in this section for historical traceability; only its State, Value,
  Evidence, and Depends on fields change.
* New questions take the next integer even when earlier questions are resolved.
* Chat answers may refer to the number, but the durable resolution is the sourced `LD-###` row.

## 4. Handoff — the orchestration contract

The orchestrating agent's document. Sections, in this order:

### Handoff title

`# <id> — <title> Handoff`

### Source documents

* **Contains:** one row per foundation role — origin, requirements, decisions — with a relative link: `| Role | Document |`.
* **Excludes:** any content from those documents.
* **Written by:** the author.
* **Done when:** every link resolves.

### Why this work exists

* **Contains:** a short summary of the need, drawn from the origin documents and citing them.
* **Excludes:** requirements, decisions, and solutions. Anything the summary would need that the origin does not say is an open question for the user.
* **Written by:** the author.
* **Done when:** every sentence traces to an origin passage.

### Recommended delivery order

Contains, in this order:

1. A dependency diagram in a `text` block — every ticket, and an arrow for every dependency.
2. The wave table. Each ticket ID links to its ticket file; `Purpose` is one sentence.

   ```markdown
   | Wave | Tickets | Parallel? | Purpose |
   | --- | --- | --- | --- |
   | 1 | [SCRIBE-01](./tickets/SCRIBE-01.md) | No | Establish the shared contracts once. |
   ```

3. One line giving the ticket count and wave count, plus any sequencing reason the table cannot show — e.g. two tickets run in sequence because both touch the same boundary.
4. **Confirmed:** who confirmed this order, and when.

* **Excludes:** ticket goals, checklists, and ownership (→ ticket files).
* **Written by:** the author, after the user confirms the order. Afterwards the orchestrating agent edits it only to add a ticket (see Ticket naming) or to record a wave's status.
* **Done when:** every ticket appears in the table exactly once; every ticket's `Depends on` matches its arrows; no two tickets marked parallel within a wave share exclusive ownership; every `REQ` is served by some ticket.

The orchestrating agent enforces this order:

* Waves run in order. A ticket starts only after every ticket it depends on is merged.
* Tickets run in parallel only within one wave, and only when their exclusive ownership does not overlap.
* A wave's tickets are reviewed and merged before the next wave starts.

### Agent dispatch and merge rules

Contains these numbered rules, each stating this handoff's actual value:

1. **Dispatch prompt.** The orchestrating agent sends the implementation agent, verbatim, this handoff's *Rules for every low-reasoning implementation agent*, *Required evidence for every ticket*, and *Compact Audit Trail Output Rule* sections, followed by the complete ticket file. The agent reads only these and the documents the ticket cites.
2. **Base.** Every ticket starts from `<base branch or commit>` as it stands after the previous wave's merges.
3. **Isolation.** Every ticket gets its own fresh worktree and branch — `<branch convention>` at `<worktree convention>` — never the orchestrating agent's checkout, and never a worktree another ticket uses. A branch or worktree that already exists under that name is a collision: stop and report it, and never delete, reset, or reuse it.
4. **No overlapping concurrency.** Two tickets whose exclusive ownership overlaps never run at the same time.
5. **Testing.** Before reporting, the implementation agent runs `<gate commands>` and the ticket's exit gate, and records each exact command and result.
6. **Commit and push.** The implementation agent commits only its owned files and `<pushes its branch | keeps it local>`. It never merges.
7. **Review and merge.** The orchestrating agent reviews the exact commit: confirms it descends from the wave base, inspects every changed file against the ticket's ownership, reruns the gates, validates the exit gate, writes the audit record, and merges only when no in-scope finding is unresolved. It then confirms the next wave's prerequisites.
8. **No stacking.** Later waves start from the updated base. An implementation agent never builds on another ticket's unmerged branch.
9. **Collisions.** A ticket that needs a file another ticket owns stops and reports the file, symbol, and reason. It never widens its own scope.
10. **Notification.** `<completion notification command>` — after pushing and before reporting, and before asking any blocking question.

* **Excludes:** anything specific to one ticket.
* **Written by:** the author.
* **Done when:** every rule states this handoff's value — base, branch and worktree convention, gate commands, push policy, and notification command.

### Rules for every low-reasoning implementation agent

Start from this list. Fill in the values; keep every rule.

```markdown
- [ ] Read the complete dispatch prompt and the target repo's agent instructions before editing.
- [ ] Display the ticket's checklist in chat before editing, and update it as work proceeds.
- [ ] Confirm the assigned branch, worktree, starting commit, clean tracked state, and the exact files the ticket owns.
- [ ] Make no remote change beyond the dispatch rules' push policy.
- [ ] Make no architectural decision the ticket omits. Stop and report the exact missing decision instead of improvising.
- [ ] Change only the ticket's owned files. If another file is required, stop and record the file, symbol, and reason.
- [ ] Follow the repo conventions in requirements <REQ IDs>.
- [ ] Record any material departure from the requirements' evidence, and the constraint that forced it. Make no unrequested improvements.
- [ ] Avoid formatting churn, dependency changes, broad cleanup, and speculative abstractions.
- [ ] Run the dispatch rules' gate commands and `git diff --check`.
- [ ] Inspect the complete diff for unrelated edits, debug output, dead code, and duplicate mechanisms.
- [ ] Check a checklist item, exit-gate condition, or objective only with evidence. Otherwise leave it unchecked and write the reason after it.
- [ ] Commit only the ticket's owned files, and confirm the worktree is clean afterwards.
- [ ] Send the completion notification per the dispatch rules.
- [ ] Stop after the commit and report. The orchestrating agent reviews and merges.
```

* **Contains:** the standing constraints that apply to every ticket.
* **Excludes:** anything specific to one ticket (→ the ticket), and repo conventions restated in full (cite their `REQ` IDs).
* **Written by:** the author, from the list above.
* **Done when:** every rule can be checked against a commit, a diff, or the agent's report.

### Required evidence for every ticket

```markdown
- Starting commit (full SHA)
- Branch and worktree path
- Final commit (full SHA)
- WHY: the exact ticket requirement the change addresses
- HOW: the seam changed, and why it is the narrowest allowed one
- WHAT: the resulting behavior, and the behavior explicitly preserved
- One changed-file row per file: file | owning evidence | exact reason | resulting behavior
- Exact verification commands and results
- Manual or browser check result, or the honest reason it is pending
- Final `git status --short --branch`
- Confirmation that no remote operation happened beyond the push policy
```

* **Contains:** the fixed list of facts every implementation agent returns.
* **Excludes:** narrative, reasoning, and restated checklist items.
* **Written by:** the author, as the list above. The implementation agent returns these facts in its final report; chat is only the transfer, and the orchestrating agent records them in the ticket's audit record.
* **Done when:** each item can be verified from git or command output.

### Compact Audit Trail Output Rule

Include verbatim:

````markdown
For each required objective, update only:

```md
### <Objective>
**State:** Resolved | Unresolved
**Value:** <one concise statement of what is established or still open>
**Evidence:** <direct pointer(s) only>
**Depends on:** <only if unresolved>
```

Output rules:

* `Value` should normally be one sentence.
* `Evidence` should contain pointers, not explanations of the evidence.
* Prefer `file:symbol`, `file:lines`, test name, route, commit, or artifact reference.
* Do not restate implementation history, verification procedure, reasoning, or unaffected code.
* Omit `Depends on` when resolved unless the dependency is essential to understanding the state.
* The objective should contain only enough information for a reviewer to understand the conclusion and inspect its source.
````

* **Contains:** exactly this format and these output rules.
* **Excludes:** any per-ticket content.
* **Written by:** the author, verbatim.
* **Done when:** the text matches the block above.

### Audit records

One record per ticket, headed `### <TICKET-ID> audit`, reading `Pending` until the ticket's first review:

```markdown
### <TICKET-ID> audit

- **Status:** Pending | Changes requested | Accepted and merged
- **Reviewed commit:** <full SHA>
- **Required evidence:** <each item from Required evidence for every ticket, as returned and verified>
- **Independent verification:** <commands the orchestrating agent reran, and their results>
- **Scope verdict:** Pass | Fail — against the ticket's exclusive ownership
- **Correctness verdict:** Pass | Changes requested — against the exit gate and objectives
- **Merge verdict:** Merged | Held — <reason>
- **Merged commit:** <full SHA>

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
```

* **Contains:** the orchestrating agent's verdicts and findings for one ticket, against an exact commit.
* **Excludes:** the implementation agent's objective values (cite the ticket's objective headings instead) and any claim not independently verified.
* **Written by:** the orchestrating agent only, after each review.
* **Done when:** the merge verdict names the exact reviewed commit, and every finding has a disposition and a resolution.

Each finding gets an ID, `F1`, `F2`, … within its ticket. When a finding needs correction, the orchestrating agent adds an objective named `### F<n> — <title>` to the ticket's Objectives, with empty values, and dispatches the ticket again. The finding's evidence and disposition stay in this record; the implementation agent's fix is recorded in the ticket objective.

## 5. Ticket — one unit of work

Each ticket is its own file, because it is what the orchestrating agent hands off. The author writes the frame; the implementation agent fills in the checkboxes and objectives.

### Ticket naming

* `<PREFIX>-<NN>`, numbered in delivery order: `SCRIBE-01`, `SCRIBE-02`. `<PREFIX>` is the origin's ticket id when it has one, otherwise a short uppercase name for the work.
* A ticket added after the order is confirmed takes the number it follows, plus a letter — `SCRIBE-04A`, `SCRIBE-04B` — so no existing ticket is renumbered. The orchestrating agent adds it to the delivery order in the same pass.
* The ID is the file name, the ticket heading, and the audit record's name.

### Ticket title

`# <TICKET-ID> — <title>`

### Header

```markdown
**Handoff:** [<id>-handoff.md](../<id>-handoff.md)
**Serves:** REQ-###, REQ-###
**Depends on:** <ticket IDs merged first, or Nothing>
**May run in parallel with:** <ticket IDs, or Nothing>
**Branch slug:** `<slug>`
**Exclusive production ownership:** <paths or globs only this ticket may change>
**Must not change:** <paths, areas, or behavior this ticket must leave alone>
```

* **Contains:** exactly these fields, each with a value.
* **Excludes:** instructions (→ build checklist).
* **Written by:** the author.
* **Done when:** `Depends on` and `May run in parallel with` match the delivery order, ownership is anchored to paths or globs, and no ticket it may run in parallel with shares its ownership.

### Goal

* **Contains:** one paragraph stating the outcome, and what this ticket must not turn into.
* **Excludes:** steps (→ build checklist).
* **Written by:** the author.
* **Done when:** the outcome can be verified by the exit gate.

### Build checklist

* **Contains:** `- [ ]` items, each one action with an observable result.
* **Excludes:** acceptance conditions (→ exit gate).
* **Written by:** the author writes the items; the implementation agent checks them.
* **Done when:** every item is checked with evidence, or left unchecked with the reason written after it.

### Exit gate

* **Contains:** `- [ ]` conditions that must hold before the orchestrating agent accepts the ticket, each verifiable from a test, a command, or the diff.
* **Excludes:** steps (→ build checklist).
* **Written by:** the author; the implementation agent checks them; the orchestrating agent validates them in the audit record.
* **Done when:** every condition is checked with evidence, or unchecked with the reason. An unchecked condition blocks acceptance.

### Out of scope

* **Contains:** adjacent work this ticket must not do.
* **Excludes:** repeats of `Must not change`.
* **Written by:** the author.
* **Done when:** each item names work that another ticket owns or that the handoff defers.

### Objectives

```markdown
## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### <Objective>
**State:**
**Value:**
**Evidence:**
**Depends on:**
```

* **Contains:** one objective per boundary the orchestrating agent will audit, named by the author, with values left empty. Every ticket includes `Scope and architecture compliance` and `Implementation completeness`.
* **Excludes:** pre-filled states, and objectives the orchestrating agent cannot audit.
* **Written by:** the author names them; the implementation agent fills them in after implementing; the orchestrating agent adds `F<n>` objectives for findings.
* **Done when:** every objective has a State, every Resolved objective has direct evidence, and every Unresolved objective names what it depends on.

## How the documents reference each other

* **Foundation chain, upstream only.** Decisions → requirements → origin. Origin links to nothing.
* **The handoff links to what it coordinates** — the foundation documents and every ticket file.
* **A ticket links to the handoff** and cites requirement and decision IDs. It never restates them.
* **One home per fact.** A requirement lives in requirements, a decision in decisions, an objective's value in its ticket, and a verdict in the handoff's audit record. Everything else cites it.
* **Stable IDs.** `REQ`, `EV`, `LD`, open-decision numbers, ticket, and finding IDs are never renumbered or reused. A superseded or resolved item stays in place, marked, pointing at its replacement or locked decision.
* **Relative links** inside the parent folder, so the set moves as one.

## Order of work

1. Resolve the parent folder.
2. Find the origin documents. Stop if there are none.
3. Find the requirements document. Stop if there is none; otherwise flesh it out.
4. Create the decisions ledger and numbered open-decision register, or adopt the existing ones.
5. Resolve every material open decision that would change ticket boundaries, ownership, or acceptance; keep each resolved question in the register pointing to its `LD-###` row.
6. Draft the delivery order — tickets, dependencies, waves, and ownership — so every requirement is served, and get the user's confirmation.
7. Write each ticket file.
8. Write the handoff, with a `Pending` audit record per ticket.
9. Check every section's **Done when** condition. Report each document's path, what was added to requirements, and every open question: unsourced requirements, unconfirmed decisions, and failed conditions.

## Do not

* Do not infer an origin, a requirement, or a decision. A missing source means stop or ask.
* Do not edit an origin document.
* Do not put evidence in decisions, or decisions in requirements.
* Do not restate a fact outside its home; cite its ID.
* Do not renumber an ID or delete a superseded row.
* Do not remove a resolved open-decision entry; retain it in place and point it to its locked decision.
* Do not dispatch a ticket before every ticket it depends on is merged, or run two tickets with overlapping ownership at the same time.
* Do not let two agents write to the same file at once.
* Do not pre-fill an objective's State or check an item without evidence.
