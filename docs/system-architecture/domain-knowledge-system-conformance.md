# Domain Knowledge System: conformance baseline

Compares [domain-knowledge-system.md](domain-knowledge-system.md), the founding
document, against [domain-knowledge-system/](domain-knowledge-system/), the template
built from it.

Reviewed 2026-09-04. Both sources read in full for this review.

Status vocabulary matches `docs/_templates/project-docs-README.template.md`:

| Status | Meaning here |
| --- | --- |
| `Conforms` | The document's requirement is present in the template |
| `Improved` | Present, and the template makes it more testable than the document does |
| `Diverges` | Deliberately different, with the reason recorded below |
| `Partial` | Some of the requirement present, some absent |
| `Absent` | Required by the document, not in the template |

## Verdict

| Status | Count |
| --- | --- |
| Conforms or Improved | 13 |
| Diverges deliberately | 5 |
| Partial | 17 |
| Absent | 8 |

The template is strong on the specification half and weak on everything downstream
of retrieval. Three structural gaps account for most of the Partial and Absent rows,
and they are listed under Findings before the section table.

## Findings, ranked

### 1. `domains/` has no scaffold, which is the half 2.1 is actually about

`specs/` ships 80 named files across 7 disciplines, discoverable by listing a
directory. `domains/` ships one README describing a shape in prose. Section 2.1 and
Rule 16 state that the knowledge topology should resemble the software topology, and
that statement is about domains and features, not about specifications.

The consequence is mechanical, not cosmetic. Retrieval works by matching against file
names in a listing. Specifications are retrievable. Domains and features are not,
because no files exist and no naming convention is defined beyond a prose sketch. The
retrieval mechanism the template is built around covers one half of the tree.

### 2. Decisions and invariants have no identifiers

The document uses `FE-021` for a decision and `FE-INVARIANT-007` for an invariant.
The template's feature node holds Decisions and Invariants as prose sections with no
IDs.

Four of the fourteen questions in section 17 become unanswerable as a result: which
decision introduced this behavior, which decisions have no corresponding tests, which
defects repeatedly violate the same invariant, and the defect-to-invariant link that
section 19's trace depends on. Nothing can cite a decision or an invariant, so nothing
can point at one.

Specifications have the same problem in a milder form. A stub carries a file name and
no ID, and the ID convention is never stated, so the first `Governs` entry written
against `specs/ui-ux/overlays.md` has to invent its prefix.

### 3. There is a read path and no write path

`selection-prompt.md` implements items 1 through 5 of section 12's thirteen Feature
Expert responsibilities. Items 6 through 13, which are decide, implement, test, update
feature knowledge, update domain knowledge, propose specification changes, record
traceability, and produce QA evidence, have no prompt, no template, and no trigger.

Section 18's nine-phase lifecycle has the same shape: phases 2 through 4 are
implemented, phases 1, 5, 6, 7, 8, and 9 are not. Section 29's orchestrator, which is
what would detect that a phase was skipped, does not exist in any form.

The system as built can assemble context and cannot record what it learned, which
inverts the document's stated purpose in section 1.

### 4. The instantiated tree has no entry point for an agent

Step 2 of the template's own instructions says to delete `README.md`. After
instantiation the tree contains `selection-prompt.md` and nothing that tells an agent
what the folder is, what it may write, or where. The document's section 1 requires
that any sufficiently capable agent reconstruct expertise from the tree alone.

### 5. `templates/` holds two of the seven entries section 23 requires

Present: `spec-entry.template.md`, `feature-node.template.md`.
Absent: `domain.md`, `decision.md`, `context-artifact.md`, `qa-review.md`,
`regression.md`.

The three absent ones that matter most are the context artifact (section 10 gives a
full schema), the QA review (section 15 gives fifteen checks), and the decision
(section 25 gives nine sections). Each is a first-class artifact in the document.

## Section by section

| Sec | Requirement | Status | Evidence in the template | Divergence or gap |
| --- | --- | --- | --- | --- |
| 1 | Preserve the chain of reasoning; an agent reconstructs expertise without the original chat | Partial | Governs, Decisions, Invariants, History cover six of the ten links | "What was implemented" and "where" deliberately not stored; "how it was reviewed" has a folder and no template; no context-artifact template |
| 2.1 | Knowledge topology resembles software topology | Absent | `domains/README.md` describes a shape | No files, no naming convention, not retrievable by listing. Finding 1 |
| 2.2 | Thirteen named persistent assets | Partial | Nine present in some form | Interfaces, implementation references, and ticket artifacts absent; defects absent as a folder; tests only as per-invariant `Proven by` |
| 2.3 | The eight-link traceability chain | Partial | Six links have a home | Decision-to-code deliberately unstored; the final durable-knowledge-update step has no mechanism |
| 3.1 | Specification defined and authoritative | Conforms | `specs/README.md`, 80 subject files across 7 disciplines | Stubs carry no ID and no ID convention is stated |
| 3.2 | Domain as a meaningful area | Partial | Defined in `domains/README.md` | Prose only. Finding 1 |
| 3.3 | Feature as bounded product behavior | Improved | Defined, plus a promotion test the document does not have | Prose only. Finding 1 |
| 3.4 | Feature knowledge: ten contents | Diverges | Six sections retained | Interfaces, implementation locations, and tests-as-map removed deliberately; edge cases and known defects were not considered and have no home |
| 3.5 | Feature Expert composition formula | Partial | `selection-prompt.md` implements it as deterministic traversal | The prompt enters from specifications only. A task against an existing feature has no direct entry path |
| 3.6 | Context Artifact as synthesized package | Partial | `artifacts/context/` exists and is described | No template; section 10's schema is not reproduced |
| 4 | Store knowledge at the narrowest scope where it is universally true | Improved | Two-consumer test in `specs/README.md`, promotion test in `domains/README.md` | None |
| 5 | Specifications answer what rule; features answer how and why | Conforms | `domains/README.md` states nodes never restate rules | None |
| 6 | Specifications may be contextual and nested | Diverges | Flat files: `navigation-persistent.md`, `tree-navigation.md`, `modals.md` | One nesting level removed. Grouping such as all navigation rules is no longer selectable as a unit. Accepted because a flat listing is what retrieval reads |
| 7 | Fan-out to parallel resolvers, fan-in to one artifact | Diverges | Single sequential pointer traversal | No fan-out at all. Correct at 32 files, unproven at 500. The scale threshold is not stated anywhere |
| 8 | Resolver output schema: ID, source, revision, relevance, applicability, ambiguity | Partial | The prompt's report covers relevance and applicability | Revision and possible ambiguity are not required outputs |
| 9 | Smallest sufficient authoritative context | Improved | Selection by acceptance criterion; over-pull is a reported defect | None |
| 10 | Context artifact schema | Absent | Nothing | The document supplies a complete YAML schema and the template reproduces none of it |
| 11 | Provenance: id, source, revision, reason_selected | Partial | `feature-node.template.md` Governs block carries all four | The prompt's report omits revision; stubs have no IDs |
| 12 | Feature Expert workflow, thirteen responsibilities | Absent | Items 1 to 5 via the selection prompt | Items 6 to 13 have no prompt, template, or trigger. Finding 3 |
| 13 | Promote generalized discoveries into specifications | Improved | Two-consumer test, plus the inconsistent-behavior branch that produces a defect list | None |
| 14 | QA independent, receives eight named inputs | Partial | `artifacts/qa/` described | No template, no prompt, no statement of the eight inputs |
| 15 | Fifteen QA checks | Partial | Five appear in `artifacts/README.md` | Ten unrepresented; no qa-review template |
| 16 | Traceability graph, twelve edges | Partial | Eight edges have a home | `implemented-by` unstored by choice; `reviewed-by` has no back-link from a node to its reviews; `discovered-by` not represented |
| 17 | Fourteen questions the system should answer | Partial | Eight answerable | Four blocked by missing decision and invariant IDs; one needs `specifications.yaml`, which is deferred. Finding 2 |
| 18 | Nine-phase ticket lifecycle | Absent | Phases 2 to 4 | Phases 1, 5, 6, 7, 8, 9 absent. Finding 3 |
| 19 | Defects enter through the same system | Absent | History mentions regressions | No `artifacts/regressions/`, no regression template, no defect-to-invariant link because invariants have no IDs |
| 20 | Knowledge in a separate repository | Conforms | Knowledge in dustin-thomason, applications in their own repositories | None |
| 21 | Record application and knowledge revisions | Conforms | `Reviewed against` block requires both | `implemented_in` and `documented_in` for completed tickets absent, because ticket records do not exist |
| 22 | Must be movable into the application without restructuring | Conforms | Self-contained copyable folder | The root README's relative link to the methodology document breaks when the folder moves |
| 23 | Proposed repository structure | Partial | All 7 spec disciplines; `artifacts/context/` and `artifacts/qa/`; 2 of 7 templates | Root files omitted deliberately; `domains/` unscaffolded; `artifacts/tickets/`, `investigations/`, `regressions/` absent; `dependencies.yaml` and `traceability.yaml` never mentioned; 5 templates absent. Finding 5 |
| 24 | Feature knowledge template, fourteen sections | Diverges | Six sections plus `Reviewed against` | Four removed deliberately as rebuildable. Scope, Domain, Edge Cases, and Known Limitations were never considered and are unaddressed |
| 25 | Decision template, nine sections | Absent | A Decisions section inside the node | No standalone template. No ID, Status, Context, Verification, or Consequences. `Rejected` is an addition the document does not have |
| 26 | Specification template, eight sections | Conforms | `spec-entry.template.md` matches all eight | None. Best-conformed section in the document |
| 27 | Context artifact retained as evidence | Partial | `artifacts/README.md` states retention | Nothing defines its shape, so what gets retained is undefined |
| 28 | History at four levels | Partial | Feature and area History sections | Project changelog omitted deliberately; ticket-level history absent because `artifacts/tickets/` does not exist |
| 29 | Orchestrator enforces process and detects missing artifacts | Absent | Nothing | The four named detections are exactly the failures Finding 3 makes possible |
| 30 | Conditional fan-out to control cost | Diverges | No fan-out, so conditionality does not apply | Consistent with section 7's divergence; the same unstated scale threshold |
| 31 | Cache retrieval by specification revision set | Absent | Governs carries revisions, which is the input | No mechanism. The document itself frames this as eventual |
| 32 | Eight things the system is not | Improved | All eight respected; the removals in section 24 are what enforce "not a second copy of the source code" | None |
| 33 | Sixteen foundational rules | Partial | Nine met, five partial, two unmet | Rule 9 (fan out and fan in) unmet by choice; Rule 16 (topology resembles software) unmet for domains |
| 34 | Completion definition, ten questions | Partial | Seven answerable | "Where is it implemented" unstored by choice; "how was it reviewed" and "what knowledge changed" have no artifact |
| 35 | Working name, `<project>-knowledge`, future `.domain/` | Conforms | Copyable folder, implementation-agnostic naming | Instantiation target is `docs/<project>/` rather than `.domain/`, consistent with section 20 |
| 36 | V1 goal, twelve items | Partial | 3 complete, 6 partial, 3 absent | Absent: domain folders, feature folders, fan-out retrieval. Partial: specification set, decisions, context artifacts, Feature Expert, QA review, history |

## Deliberate divergences, with the reason each was accepted

These are not gaps. Each was decided during the session that produced the template and
each should stay decided unless new evidence overturns it.

| Divergence | Document says | Template does | Why |
| --- | --- | --- | --- |
| Feature node has six sections, not fourteen | Sec 24 | Governs, Decisions, Invariants, Not owned, Affects, History | Purpose, Interfaces, Implementation Map, and Test Map are rebuildable from the repository in minutes and go stale faster than the code. Storing them makes the tree a second copy of the source, which section 32 forbids |
| Implementation locations are not stored | Sec 3.4, 24 | Resolved at task time | A stored map used as a boundary prevents discovering an unrecorded coupling, which defeats the Code Impact Resolver in section 8 |
| Specification tree is flat within a discipline | Sec 6 | `specs/ui-ux/tree-navigation.md` rather than `specs/ui-ux/navigation/tree.md` | Retrieval reads a directory listing. Nesting hides names one level deeper without adding selection power |
| No fan-out | Sec 7, 30 | Single sequential traversal | At 32 spec files, listing all names is one operation and cheaper than dispatching six resolvers. Revisit when a discipline exceeds what one listing conveys |
| Root files omitted | Sec 23 | No PHILOSOPHY, ROADMAP, or CHANGELOG | Roadmap and pending decisions live beside the code, the project changelog follows the existing `docs/<project>/` convention, and philosophy belongs in the methodology document |
| Retrieval by file name, not by an index of trigger conditions | not in the document | Acceptance criteria matched against folder and file names | Standardizable across systems and auditable by a reviewer with no domain knowledge. The cost is that file naming must stay honest |
| Every candidate subject exists as a stub | not in the document | 80 files carrying `Status: Not written` | A subject with no file cannot be selected and its absence produces no signal. A stub converts a missing rule into a reported gap |

## What to build, in dependency order

1. **Identifier convention.** A single file stating how specification, decision, and
   invariant IDs are formed, and where each is recorded. Everything in Finding 2 and
   four of section 17's questions depend on this, and it blocks items 2 and 4.
2. **`domains/` scaffold.** A naming convention and a starting shape that make areas
   and features discoverable by listing, the way specifications already are.
   Finding 1, Rule 16, section 36 items 3 and 4.
3. **Agent entry README.** A file that survives instantiation and states what the
   tree is, what an agent may read, what it must write, and in what order. Finding 4.
4. **The five missing templates.** `context-artifact.md` first, since section 10
   supplies the schema and section 27 makes it the object QA reads. Then
   `qa-review.md` from section 15's fifteen checks, then `decision.md` from section
   25, then `domain.md`, then `regression.md`. Finding 5.
5. **Write-back prompt.** The counterpart to `selection-prompt.md`, covering section
   12 items 6 to 13 and section 18 phases 5, 6, and 9. Finding 3.
6. **QA prompt.** Section 14's eight inputs and section 15's fifteen checks, run
   against the retained context artifact rather than against a conversation.
7. **Missing-artifact detection.** Section 29's four checks, which is what makes
   items 5 and 6 enforceable rather than optional.
8. **Deferred, with a stated trigger.** `artifacts/tickets/`,
   `artifacts/investigations/`, `artifacts/regressions/` on first occurrence.
   `indexes/specifications.yaml` derived when the first Governs entry exists.
   `features.yaml` when listing names stops being sufficient. `dependencies.yaml`
   and `traceability.yaml` are not yet justified by any observed need.

## Open question this review could not settle

Section 7's fan-out and section 30's conditional cost model were replaced with
sequential traversal because the current tree is small. No threshold is defined at
which the replacement stops being correct. Until one is, the divergence is a judgment
that has not been tested rather than a decision that has been made.
