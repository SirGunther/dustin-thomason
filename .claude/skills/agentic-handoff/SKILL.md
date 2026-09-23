---
name: agentic-handoff
description: Build the document set an orchestrated multi-agent handoff runs on — origin, requirements, decisions, the handoff (delivery order, dispatch and merge rules, resolved/unresolved routing, agent rules, required evidence, audit format, audit records), and one file per ticket whose checkboxes and objectives the implementation agent fills in. Every section carries an operational definition. Documents are identified by role, not filename. Use when the user says "handoff", "build the handoff", "set up the handoff docs", or asks to prepare work for an orchestrator and implementation agents.
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

### Authoring and execution reasoning boundary

Reasoning roles describe **execution ownership**, not separate stages of handoff authoring.

* The author completes the entire foundation set, ticket decomposition, ticket files, and handoff in
  one high-reasoning authoring run. Do not pause between the foundation and ticket-writing stages,
  ask the user to switch models, or delegate unfinished decomposition to a lower-reasoning agent.
* Tiered execution begins only after the completed handoff is delivered to the orchestrating agent.
  That orchestrating agent uses high reasoning to sequence, dispatch, review, merge, and triage.
* Lower-reasoning implementation agents receive only bounded tickets whose architecture, ownership,
  dependencies, acceptance conditions, and stop rules have already been decided.
* If the author and orchestrating agent are the same agent, the role transition still occurs only
  after every foundation document, ticket, handoff section, link, and coverage check is complete
  and the document set is committed.

This boundary prevents low-reasoning agents from making architecture decisions while also preventing
the authoring process from being fragmented across avoidable model handoffs.

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

What must be true, and the evidence of what exists that those requirements depend on. When another document disagrees with this one, this one holds until it is changed with a source. Requirements sit upstream of decisions, the handoff, and tickets, so this document never lists tickets, cites a decision, or tracks another document's status.

It must be provided. If none exists, stop and ask the user where it is. The author fleshes it out: keep its wording and structure, add what is missing (including IDs on existing items), cite a source for every addition, and gather evidence yourself rather than asking the user for anything the code or documents can answer. A requirement you cannot source goes to chat as an open question, not into the document.

### Requirements (`REQ-###`)

* **Contains:** one condition that must be true per item, each citing where it came from — an origin passage, or a named person and date.
* **Excludes:** how the condition will be met (→ decisions), facts about what exists (→ evidence), a decision ID as a source, and any list of the tickets that serve it. Coverage lives in each ticket's `Serves` field and is checked in the handoff's delivery order.
* **Written by:** provided; the author adds IDs and sourced additions.
* **Done when:** every item has an ID and a source that is an origin passage or a named person and date.

### Evidence (`EV-###`)

* **Contains:** one fact about what exists per item — a field, column, label, route, or contract — quoted exactly, with a direct pointer (`path:line`, `path:symbol`, or URL).
* **Excludes:** interpretation and choices (→ decisions).
* **Written by:** the author, read directly from the source.
* **Done when:** every pointer resolves and every quote matches its source.

### Implementation conventions

* **Contains:** how the target repo is built, as `EV-###` items with direct pointers — the module format and how code is loaded, the test harness and how tests are discovered and run, the gate commands, the dependency policy, and the repo's agent-instruction files.
* **Excludes:** process requirements such as orchestration, checklists, and notifications (→ requirements).
* **Written by:** the author, read directly from the repo.
* **Done when:** the module format, load mechanism, test harness, gate commands, dependency policy, and agent-instruction files each have an evidence item with a pointer, or a recorded absence (e.g. "no `package.json`", "no `AGENTS.md`").

### Scope boundary

* **Contains:** what may change and what is read-only, by repo or path.
* **Excludes:** per-ticket file ownership (→ each ticket's header).
* **Written by:** provided, or added by the author with a source.
* **Done when:** every repo and path the work touches is named writable or read-only.

### Readiness

* **Contains:** each prerequisite outside this document set — repository access, base branch, tooling, environment — and whether it is met.
* **Excludes:** work still to be done (→ tickets), and the status of decisions, the handoff, or tickets (each is checked by its own **Done when** condition).
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

The decisions document keeps a stable checklist and numbered register immediately after the
locked-decision ledger. This lets the user answer tersely in chat — for example,
`1. local storage is fine` — without losing which gap the answer resolves. The checklist is an
index; the detailed record is the evidence-backed authority.

```markdown
## Open Decision Checklist

- [ ] 1. <exact question requiring user authority>
- [x] 2. <resolved question> — Resolved as LD-###

## Open Decision Register

### 1. <decision question title>
**State:** Resolved | Unresolved
**Value:** <the exact open question, or `Resolved as LD-###`>
**Investigation:** <codebase and source artifacts inspected, with direct pointers>
**Why user input is required:** <the product, risk, priority, or authority choice sources cannot settle>
**Recommendation:** <one preferred answer, grounded in inspected code, best practices, and the smallest compatible change>
**Evidence:** <source pointer for the gap or resolution>
**Depends on:** <what is blocked, or —>
```

* **Contains:** every material decision question, mirrored as a checklist item and a detailed record,
  numbered from `1` upward in discovery order. Resolved entries remain in place and point to the
  resulting `LD-###` row.
* **Excludes:** the decision's implementation-shaped value once resolved (→ locked-decision ledger),
  unsupported option lists disguised as recommendations, and non-blocking implementation details.
* **Written by:** the author investigates and adds unresolved entries. When the user answers one,
  the orchestrating agent adds the sourced `LD-###` row, checks the checklist item, and changes that
  numbered entry to `Resolved as LD-###` in the same pass.
* **Done when:** every material gap is numbered; every resolved item points to its locked decision;
  every unresolved item names what it blocks, proves why existing sources cannot answer it, and
  offers one evidence-backed recommendation.

Question-admission gate:

1. Write the exact prospective question as an unchecked checklist item.
2. Search the implementation repository, origin documents, requirements, decisions, and named
   reference systems for an answer. Record the exact files, symbols, or source passages inspected.
3. If those sources answer the question, do not ask the user. Record the sourced outcome in the
   appropriate evidence or locked-decision record and mark the checklist item resolved.
4. If the sources do not answer it, explain what irreducible product, risk, priority, or authority
   choice remains. A statement such as “the code does not say” is insufficient without showing the
   conflicting or absent behavior that makes user direction necessary.
5. Derive one recommendation from the inspected code, applicable platform/security best practices,
   and the smallest change compatible with existing behavior. State the recommendation plainly and
   explain its decisive tradeoff; do not present an unranked menu of options.
6. Only after `Investigation`, `Why user input is required`, and `Recommendation` are complete may
   the question be asked. Ask with the recommendation included. If any field is missing,
   unsupported, or conclusory, investigate again instead of asking.

This gate adds due diligence; it does not replace the origin, requirements, evidence, locked
decisions, or ticket work already completed.

Numbering rules:

* Never renumber, reorder, reuse, migrate, or delete an entry.
* A resolved entry stays in this section for historical traceability; only its State, Value,
  Investigation, Why user input is required, Recommendation, Evidence, and Depends on fields change.
  Preserve the recommendation that was presented even when the user chooses differently; the
  locked decision records the authoritative outcome.
* New questions take the next integer even when earlier questions are resolved.
* Checklist state mirrors the detailed record: unchecked means unresolved; checked means a locked
  decision exists.
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

1. **Dispatch prompt.** The orchestrating agent sends the implementation agent, verbatim, this handoff's *Resolved and unresolved work*, *Rules for every low-reasoning implementation agent*, *Required evidence for every ticket*, and *Compact Audit Trail Output Rule* sections, followed by the complete ticket file. The agent reads only these and the documents the ticket cites.
2. **Base.** Every ticket starts from `<base branch or commit>` as it stands after the previous wave's merges.
3. **Isolation.** Every ticket gets its own fresh worktree and branch — `<branch prefix>/<slug>` at `<worktree root>\<slug>`, where `<slug>` is the ticket's bare branch slug — never the orchestrating agent's checkout, and never a worktree another ticket uses. A branch or worktree that already exists under that name is a collision: stop and report it, and never delete, reset, or reuse it.
4. **No overlapping concurrency.** Two tickets whose exclusive ownership overlaps never run at the same time.
5. **Testing.** Before reporting, the implementation agent runs `<gate commands>` and the ticket's exit gate, and records each exact command and result.
6. **Manual and live checks.** Every browser, device, or live-environment check names who runs it — the implementation agent with `<tool>`, or the orchestrating agent — and how any runtime secret, such as an endpoint, token, or credential, is entered without being written into an artifact, prompt, commit, or log.
7. **Commit and push.** The implementation agent commits only its owned files and `<pushes its branch | keeps it local>`. It never merges.
8. **Review and merge.** The orchestrating agent reviews the exact commit: confirms it descends from the wave base, inspects every changed file against the ticket's ownership, reruns the gates, validates the exit gate, writes the audit record, and merges only when no in-scope finding is unresolved. It then confirms the next wave's prerequisites.
9. **No stacking.** Later waves start from the updated base. An implementation agent never builds on another ticket's unmerged branch.
10. **Collisions.** A ticket that needs a file another ticket owns stops and reports the file, symbol, and reason. It never widens its own scope.
11. **Notification.** `<completion notification command>` — after pushing and before reporting, and before asking any blocking question.

* **Excludes:** anything specific to one ticket.
* **Written by:** the author.
* **Done when:** every rule states this handoff's value — base, branch prefix and worktree root, gate commands, who runs each manual and live check and how runtime secrets are entered, push policy, and notification command.

### Resolved and unresolved work

Start from this list. State this handoff's evidence standard; keep every route.

```markdown
- **Resolved** means <this handoff's evidence standard: what the evidence must point to, and which path the verification must exercise>.
- A passing test proves only what it exercises. It counts toward Resolved only when the ticket shows that it crosses the path the standard names.
- **Correctable within the ticket's ownership:** the orchestrating agent records the finding as `F<n>` in the ticket's audit record, adds an empty `### F<n> — <title>` objective to the ticket, and dispatches the same branch again. The ticket stays unmerged.
- **Needs other ownership, or found after merge:** the orchestrating agent creates the next lettered ticket after the one that caused it (see Ticket naming), adds it to the delivery order, and records the dependency.
- **Needs user authority or an external environment:** the objective stays Unresolved and names what it depends on. The agent sends the completion notification and stops only that path. No agent invents a decision or claims completion.
- Resolved, superseded, and rejected findings stay in their original record. They are never deleted or moved.
```

* **Contains:** the evidence standard for **Resolved**, and exactly one route for each kind of unresolved outcome — correctable within the ticket's ownership, needs other ownership or found after merge, needs user authority or an external environment.
* **Excludes:** individual findings (→ audit records) and ticket-specific acceptance conditions (→ each ticket's exit gate).
* **Written by:** the author, from the list above.
* **Done when:** the Resolved standard names what the evidence must point to and which path the verification must exercise, and every kind of unresolved outcome has exactly one route.

### Rules for every low-reasoning implementation agent

Start from this list. Fill in the values; keep every rule.

```markdown
- [ ] Read the complete dispatch prompt and the target repo's agent instructions before editing.
- [ ] Display the ticket's checklist in chat before editing, and update it as work proceeds.
- [ ] Confirm the assigned branch, worktree, starting commit, clean tracked state, and the exact files the ticket owns.
- [ ] Make no remote change beyond the dispatch rules' push policy.
- [ ] Make no architectural decision the ticket omits. Stop and report the exact missing decision instead of improvising.
- [ ] Change only the ticket's owned files. If another file is required, stop and record the file, symbol, and reason.
- [ ] Follow the implementation conventions in requirements <EV IDs>.
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
* **Excludes:** anything specific to one ticket (→ the ticket), and repo conventions restated in full (cite their `EV` IDs).
* **Written by:** the author, from the list above.
* **Done when:** every rule can be checked against a commit, a diff, or the agent's report, and the conventions rule cites the requirements' implementation-convention evidence IDs.

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

Each finding gets an ID, `F1`, `F2`, … within its ticket, and is routed by *Resolved and unresolved work*. The finding's evidence and disposition stay in this record; the implementation agent's fix is recorded in the ticket's `F<n>` objective.

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
**Branch slug:** `<bare-kebab-slug>`
**Exclusive production ownership:** <paths or globs only this ticket may change>
**Must not change:** <paths, areas, or behavior this ticket must leave alone>
```

* **Contains:** exactly these fields, each with a value.
* **Excludes:** instructions (→ build checklist), and any prefix or path in the branch slug (the dispatch rules add those).
* **Written by:** the author.
* **Done when:** `Depends on` and `May run in parallel with` match the delivery order; the branch slug is bare kebab-case with no `/` or `\` (e.g. `sayai-01-provider-profiles`); ownership is anchored to paths or globs; and no ticket it may run in parallel with shares its ownership.

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

* **Contains:** `- [ ]` conditions that must hold before the orchestrating agent accepts the ticket, each verifiable from a test, a command, the diff, or a manual or live check assigned by the dispatch rules.
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

* **Contains:** one objective per boundary the orchestrating agent will audit, named by the author, with values left empty. Each is resolvable within this ticket's ownership before it merges. Every ticket includes `Scope and architecture compliance` and `Implementation completeness`.
* **Excludes:** pre-filled states, objectives the orchestrating agent cannot audit, and verification that needs a later ticket's wiring — that is an objective of the ticket that wires the path.
* **Written by:** the author names them; the implementation agent fills them in after implementing; the orchestrating agent adds `F<n>` objectives for findings.
* **Done when:** no objective needs work outside this ticket's ownership, or a later ticket, to reach Resolved; and, once filled in, every objective has a State, every Resolved objective has direct evidence, and every Unresolved objective names what it depends on.

### Checks across the ticket set

Run both checks on the complete set before any ticket is dispatched. A failure goes back to decisions, evidence, or the open-decision register — never to an implementation agent.

1. **Shared contracts are fixed.** Every value, shape, or interface that one ticket produces and a later ticket consumes — a stored field's format, an endpoint's form, a function's inputs and outputs, a result or error shape — is fixed by an `LD-###` or `EV-###` item and cited in both tickets.
2. **Every choice has a source.** Every behavior or design choice in a ticket's goal, build checklist, or exit gate — including user-facing layout, controls, and failure handling — traces to a `REQ`, `LD`, or `EV` item. A choice with no source goes through the question-admission gate into the open-decision register before the ticket is final.

* **Done when:** both checks pass for every ticket, and every fix is recorded as a decision or evidence item, not as ticket text alone.

## How the documents reference each other

* **Foundation chain, upstream only.** Decisions → requirements → origin. Origin links to nothing. Requirements never list tickets, cite decisions, or point at the handoff; requirement coverage lives in each ticket's `Serves` field and is checked in the handoff's delivery order.
* **The handoff links to what it coordinates** — the foundation documents and every ticket file.
* **A ticket links to the handoff** and cites requirement and decision IDs. It never restates them.
* **One home per fact.** A requirement lives in requirements, a decision in decisions, an objective's value in its ticket, and a verdict in the handoff's audit record. Everything else cites it.
* **Stable IDs.** `REQ`, `EV`, `LD`, open-decision numbers, ticket, and finding IDs are never renumbered or reused. A superseded or resolved item stays in place, marked, pointing at its replacement or locked decision.
* **Relative links** inside the parent folder, so the set moves as one.

## Order of work

1. Resolve the parent folder.
2. Find the origin documents. Stop if there are none.
3. Find the requirements document. Stop if there is none; otherwise flesh it out.
4. Create the decisions ledger, open-decision checklist, and numbered register, or adopt the existing ones. Run every prospective question through the question-admission gate before asking it.
5. Resolve every eligible material open decision that would change ticket boundaries, ownership, or acceptance; keep each resolved question checked in the register and pointing to its `LD-###` row.
6. Draft the delivery order — tickets, dependencies, waves, and ownership — so every requirement is served, and get the user's confirmation.
7. Write each ticket file.
8. Write the handoff, with a `Pending` audit record per ticket.
9. Check every section's **Done when** condition and run the *Checks across the ticket set*. Report each document's path, what was added to requirements, and every open question: unsourced requirements, unconfirmed decisions, and failed conditions.
10. Commit the complete document set. The first dispatch happens only from that commit, so every later edit to a ticket or the handoff can be compared against what was dispatched.

Steps 1–10 are one continuous high-reasoning authoring process. Do not insert a model-switch or
lower-tier implementation handoff between them. Tiered execution starts only after step 10 succeeds.

## Do not

* Do not infer an origin, a requirement, or a decision. A missing source means stop or ask.
* Do not edit an origin document.
* Do not list tickets, cite decisions, or track another document's status inside requirements.
* Do not duplicate canonical evidence in locked decisions, or decisions in requirements. An open-decision investigation may cite evidence IDs or direct source pointers only to prove why the question is eligible to ask.
* Do not restate a fact outside its home; cite its ID.
* Do not renumber an ID or delete a superseded row.
* Do not remove a resolved open-decision entry; retain it in place and point it to its locked decision.
* Do not ask an open decision until codebase/source investigation and the reason user authority is still required are both recorded.
* Do not ask an open decision without one supported recommendation, and never treat that recommendation as locked until the user confirms it.
* Do not dispatch from an uncommitted document set.
* Do not leave a shared contract or an unsourced choice in a ticket for an implementation agent to decide.
* Do not dispatch a ticket before every ticket it depends on is merged, or run two tickets with overlapping ownership at the same time.
* Do not let two agents write to the same file at once.
* Do not pre-fill an objective's State or check an item without evidence.
