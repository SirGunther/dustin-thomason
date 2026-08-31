# Domain Knowledge System

> **Working name:** Domain Knowledge System
> **Conventional directory:** `.domain/`
> **Recommended initial storage:** Separate repository
> **Primary principle:** Durable knowledge is the traceability of the software.

---

## 1. Purpose

The Domain Knowledge System is a persistent, implementation-aware knowledge layer for an application.

Its purpose is not simply to document the application.

Its purpose is to preserve the chain of reasoning that explains:

* what was requested,
* which specifications applied,
* what decisions were made,
* why those decisions were made,
* what was implemented,
* where it was implemented,
* how it was tested,
* how it was reviewed,
* what changed later,
* and what was learned from defects and regressions.

Agents are temporary.

Chats are temporary.

Model context is temporary.

**The trace is durable.**

The Domain Knowledge System exists so that any sufficiently capable agent can later reconstruct the relevant expertise without depending on the original conversation or original model.

---

# 2. Core Philosophy

## 2.1 The knowledge system should resemble the software

The organizational structure should not imitate a traditional company.

We do not primarily need:

* a CEO agent,
* a CTO agent,
* a designer agent,
* a programmer agent,
* and a tester agent.

Instead, the durable structure should reflect the actual software.

For example:

```text
Application
├── Files
│   ├── Project File Explorer
│   ├── File Upload
│   └── Recent Files
│
├── Authentication
│   ├── Login
│   ├── Sessions
│   └── Password Recovery
│
├── Subscriptions
│   ├── Plan Selection
│   ├── Cancellation
│   └── Renewal
│
└── Notifications
    ├── Email Preferences
    └── In-App Notifications
```

The knowledge topology should increasingly resemble the product topology.

---

## 2.2 Agents are ephemeral; knowledge is persistent

An agent should not become the permanent source of truth for a feature.

The persistent assets are:

* specifications,
* domain knowledge,
* feature knowledge,
* decisions,
* invariants,
* interfaces,
* implementation references,
* tests,
* ticket artifacts,
* QA evidence,
* defects,
* history,
* and traceability links.

An expert can be reconstructed from those assets whenever work needs to resume.

This allows the underlying:

* model,
* agent framework,
* IDE,
* orchestration system,
* or vendor

to change without losing the intellectual history of the application.

---

## 2.3 Traceability is the durable asset

The central model is:

```text
Requirement / Ticket
        ↓
Applicable Specifications
        ↓
Domain + Feature Context
        ↓
Implementation Decisions
        ↓
Code Changes
        ↓
Tests / Evidence
        ↓
QA Review
        ↓
Durable Knowledge Update
```

Every meaningful implementation decision should be able to answer:

> Why is this here?

And the answer should be traceable backward.

Likewise, every specification should eventually be traceable forward:

> What parts of the application depend on this rule?

---

# 3. Terminology

The terminology should distinguish persistent knowledge from temporary agents.

## 3.1 Specification

A **Specification** defines a reusable rule, constraint, philosophy, convention, or expectation for the application.

Examples:

* UI/UX specifications
* architecture specifications
* backend specifications
* data specifications
* accessibility specifications
* security specifications
* QA specifications

Specifications are authoritative.

They define **how this system is expected to behave or be built**.

Examples:

```text
UX-TREE-012
Persistent hierarchical navigation must support keyboard traversal.

ARCH-FILE-003
File identity must remain stable independently of path.

BE-UPLOAD-007
Large uploads must use multipart transfer.

QA-A11Y-008
Keyboard-accessible interactions require automated coverage.
```

Specifications should not describe one feature unless the rule is genuinely unique to that feature.

---

## 3.2 Domain

A **Domain** is a meaningful area of the application that contains related concepts, behaviors, features, and history.

Examples:

```text
Files
Subscriptions
Authentication
Notifications
Search
Billing
Projects
```

Domain knowledge explains the application-specific concepts and implementation decisions that apply across features within that area.

A domain is broader than an individual ticket and may be broader than an individual feature.

---

## 3.3 Feature

A **Feature** is a bounded piece of concrete product behavior.

Examples:

```text
Project File Explorer
Upload File Selection
Subscription Cancellation
Password Recovery
Notification Preferences
```

A feature should be narrow enough that its behavior, decisions, invariants, dependencies, and history remain understandable.

Features may share concepts without sharing implementation rules.

For example:

```text
Project File Explorer
```

and:

```text
Upload File Selection
```

both involve files and navigation, but they can have completely different UI/UX behavior because they exist on different surfaces and serve different user goals.

---

## 3.4 Feature Knowledge

Feature knowledge records **what this application actually does for that feature**.

It includes:

* applicable specification references,
* implementation decisions,
* reasons for those decisions,
* invariants,
* interfaces,
* edge cases,
* implementation locations,
* tests,
* known defects,
* historical changes.

It should not duplicate specifications.

Instead, it should point to them and explain how they were applied.

---

## 3.5 Feature Expert

A **Feature Expert** is an agent instantiated to work on a specific feature using the durable knowledge associated with that feature.

The expert is not necessarily permanent.

Conceptually:

```text
Feature Expert
=
Current Ticket
+ Feature Knowledge
+ Domain Knowledge
+ Applicable Specifications
+ Relevant Code
+ Relevant History
```

The expert is the active reasoning process.

The knowledge is the persistent asset.

---

## 3.6 Context Artifact

A **Context Artifact** is a task-specific, synthesized package containing the smallest sufficient authoritative context required to perform a ticket.

It is produced before implementation.

It may include:

* ticket requirements,
* relevant feature knowledge,
* relevant domain knowledge,
* applicable specifications,
* existing decisions,
* invariants,
* affected interfaces,
* relevant implementation locations,
* related tests,
* related defects,
* unresolved questions.

The Context Artifact becomes the primary working input for both implementation and later QA.

---

# 4. Knowledge Placement Rule

A foundational rule of the system is:

> **Store knowledge at the narrowest scope at which it is universally true.**

Examples:

### Feature knowledge

> Double-clicking a file in Project File Explorer opens it in the active editor.

This belongs to:

```text
Project File Explorer
```

### UI/UX specification

> Persistent tree navigators support arrow-key traversal.

This belongs to:

```text
UI/UX Specifications → Tree Navigation
```

### Architecture specification

> File identity is independent of file path.

This belongs to:

```text
Architecture Specifications → File Identity
```

### Backend specification

> Uploads larger than the configured threshold use multipart transfer.

This belongs to:

```text
Backend Specifications → Uploads
```

Knowledge should move upward only when it becomes generally applicable.

Feature-specific discoveries remain feature knowledge.

Reusable discoveries should become specifications.

---

# 5. Specifications vs. Feature Knowledge

This distinction prevents duplication.

A specification answers:

> **What rule applies?**

Feature knowledge answers:

> **How did this feature apply the rule, and why?**

For example:

### Specification

```text
UX-TREE-012

Persistent hierarchical navigation must support keyboard traversal.
```

### Feature decision

```text
Project File Explorer / FE-021

The explorer uses the system's persistent tree-navigation pattern.

References:
- UX-TREE-012
- UX-A11Y-009

Implementation:
- Arrow keys change active nodes.
- Right arrow expands a collapsed directory.
- Left arrow collapses or moves to the parent.

Reason:
The Project File Explorer is a persistent hierarchical navigation surface
and therefore falls under the tree-navigation specification.
```

The feature does not rewrite `UX-TREE-012`.

It references it.

---

# 6. Specifications May Be Contextual

Specifications should not be artificially universal.

For example, "navigation" does not need one global UI rule.

The specification tree may look like:

```text
UI/UX
└── Navigation
    ├── Persistent Workspace Navigation
    ├── Tree Navigation
    ├── Modal Navigation
    ├── File-Selection Navigation
    ├── Mobile Navigation
    └── Embedded Panel Navigation
```

The correct rule is selected based on the context of the feature.

This allows:

```text
Project File Explorer
```

to reference:

```text
Persistent Workspace Navigation
Tree Navigation
```

while:

```text
Upload File Selection
```

may reference:

```text
Modal Navigation
File-Selection Navigation
Drag and Drop
```

The shared concept is files.

The applicable rules differ because the feature context differs.

---

# 7. Fan-Out / Fan-In Context Discovery

The Feature Expert should not blindly ingest the entire knowledge repository.

Instead, context should be resolved before implementation.

The basic workflow is:

```text
                    TICKET
                      │
                      ▼
               Context Planning
                      │
                   fan out
       ┌──────────────┼──────────────┐
       ▼              ▼              ▼
   UX Resolver   Architecture    Backend Resolver
                     Resolver
       │              │              │
       ├──────────────┼──────────────┤
       ▼              ▼              ▼
 Feature History   Code Impact    Test Coverage
    Resolver        Resolver        Resolver
       │              │              │
       └──────────────┼──────────────┘
                      │
                    fan in
                      ▼
               CONTEXT ARTIFACT
                      │
                      ▼
                FEATURE EXPERT
```

These fan-out workers do not need to be durable experts.

They can be narrow, temporary **resolvers** or **scouts**.

Their job is to retrieve evidence, not solve the entire ticket.

---

# 8. Resolver Responsibilities

A resolver should receive:

* the ticket,
* a narrow search scope,
* a required output schema.

For example:

```text
Search only the UI/UX specifications.

Identify rules that materially constrain this ticket.

For each result return:
- specification ID,
- source,
- revision,
- relevance,
- exact applicability,
- possible ambiguity.

Do not propose implementation.
Do not summarize unrelated specifications.
```

Possible resolvers include:

```text
UI/UX Specification Resolver
Architecture Specification Resolver
Backend Specification Resolver
Data Specification Resolver
Security Specification Resolver
QA Specification Resolver
Domain Knowledge Resolver
Feature History Resolver
Code Impact Resolver
Test Coverage Resolver
Dependency Resolver
```

Only necessary resolvers should run.

---

# 9. Smallest Sufficient Context

The objective is not:

> Give the model everything.

The objective is:

> Give the model the smallest sufficient authoritative context needed to make the change safely.

This reduces:

* context pollution,
* irrelevant reasoning,
* conflicting information,
* token usage,
* accidental coupling,
* and cognitive overhead.

More context is not inherently better context.

Relevance should be resolved before implementation.

---

# 10. Context Artifact

After fan-out, results are synthesized into one artifact.

Example:

```yaml
ticket: FILE-128
feature: project-file-explorer
domain: files

requirements:
  - add keyboard-accessible folder expansion
  - preserve selection during asynchronous loading

specifications:
  uiux:
    - id: UX-TREE-012
      source: specs/uiux/navigation/tree.md
      relevance: Governs keyboard traversal of hierarchical navigation.

    - id: UX-ASYNC-004
      source: specs/uiux/state/async.md
      relevance: Governs focus behavior during asynchronous interface updates.

  architecture:
    - id: ARCH-FILE-003
      source: specs/architecture/files/identity.md
      relevance: Selection must track stable file identity rather than path.

  qa:
    - id: QA-A11Y-008
      source: specs/qa/accessibility.md
      relevance: Keyboard interaction requires automated coverage.

existing_decisions:
  - FE-021
  - FE-028

invariants:
  - Selected file remains selected after path changes.
  - Focus must never disappear during tree updates.

affected_implementation:
  - src/explorer/FileTree.tsx
  - src/state/workspaceFiles.ts

existing_tests:
  - test_keyboard_navigation
  - test_file_move_preserves_selection

open_questions:
  - Expected keyboard behavior while directory children are loading.

provenance:
  application_revision: <commit>
  knowledge_revision: <commit>
```

This artifact should be concise enough to operate from directly.

---

# 11. Provenance

Every retrieved piece of knowledge should retain provenance.

A rule reference should ideally include:

```yaml
id: UX-TREE-012
source: specs/uiux/navigation/tree.md
revision: 8f71c2
reason_selected: >
  The ticket changes keyboard behavior in persistent hierarchical navigation.
```

This allows later analysis to determine:

* which rule version governed an implementation,
* whether specifications have changed,
* what features depend on an altered specification,
* why a rule was selected,
* and whether the previous implementation remains compliant.

---

# 12. Feature Expert Workflow

One primary Feature Expert owns the implementation lifecycle for the ticket.

The Feature Expert is responsible for:

1. understanding the ticket,
2. initiating context discovery,
3. requesting necessary fan-out,
4. consuming the Context Artifact,
5. investigating relevant implementation,
6. making implementation decisions,
7. implementing the change,
8. updating tests,
9. updating feature knowledge,
10. updating domain knowledge when appropriate,
11. proposing specification changes when knowledge generalizes,
12. recording traceability,
13. producing implementation evidence for QA.

The Feature Expert is therefore the primary integrator.

The fan-out workers support it.

They do not replace it.

---

# 13. Updating Specifications

A Feature Expert may discover that an existing specification is incomplete.

For example:

> When asynchronously loading children into a tree, focus should remain on the parent until the children become interactive.

The Feature Expert must determine whether this is:

### Feature-specific

If true only for Project File Explorer:

```text
domains/files/features/project-file-explorer/decisions/
```

### Generally reusable

If true for all asynchronous tree interfaces:

```text
specs/uiux/navigation/tree.md
```

Generalized knowledge should be promoted into the relevant specification.

The feature should then reference the new specification rather than duplicate it.

---

# 14. QA Model

QA should be performed independently from implementation.

A higher-reasoning QA model can be used when appropriate.

The QA agent receives:

```text
Original Ticket
+
Context Artifact
+
Applicable Specifications
+
Feature Decisions
+
Implementation Diff
+
Updated Documentation
+
Tests
+
Test Results
```

Its primary question is:

> **Was the feature implemented correctly according to what was requested, what the system requires, and what the implementation claims to do?**

---

# 15. QA Responsibilities

The QA agent should verify:

* every requirement was addressed,
* the correct specifications were identified,
* no obviously applicable specification was omitted,
* implementation decisions are documented,
* decisions are consistent with specifications,
* implementation matches the decisions,
* feature invariants remain valid,
* appropriate tests exist,
* test behavior corresponds to documented expectations,
* new assumptions are documented,
* interfaces with other domains remain valid,
* related domain knowledge has been updated,
* generalized discoveries were promoted when appropriate,
* no specification was changed without identifying impacted features,
* documentation and implementation remain consistent.

QA is therefore not simply code review.

It is **traceability review**.

---

# 16. Traceability Graph

Conceptually, the system forms a graph:

```text
REQUIREMENT / TICKET
        │
        │ constrained-by
        ▼
SPECIFICATION
        │
        │ applied-as
        ▼
FEATURE DECISION
        │
        │ implemented-by
        ▼
CODE
        │
        │ verified-by
        ▼
TEST
        │
        │ reviewed-by
        ▼
QA EVIDENCE
```

Additional relationships can include:

```text
Feature ───── belongs-to ─────► Domain

Feature ───── depends-on ──────► Feature

Feature ───── references ──────► Specification

Defect ────── violates ────────► Invariant

Decision ──── supersedes ──────► Decision

Specification ─ governs ───────► Feature

Regression ── discovered-by ───► Test
```

This graph is what makes the knowledge base queryable.

---

# 17. Questions the System Should Eventually Answer

The knowledge system should make questions such as these easy:

```text
What specifications govern Project File Explorer?

Why does this feature behave this way?

What decision introduced this behavior?

Which code implements this decision?

Which tests prove the behavior?

What invariant did this regression violate?

What features depend on UX-TREE-012?

Which specifications changed since this feature was last reviewed?

Which feature decisions have no corresponding tests?

Which implementation changes have no documented decision?

Which defects repeatedly violate the same invariant?

What features require review if ARCH-FILE-003 changes?

What did the QA agent verify when this ticket was completed?
```

---

# 18. Ticket Lifecycle

A standard ticket should move through the following lifecycle.

## Phase 1 — Intake

Identify:

* ticket,
* domain,
* feature,
* expected behavior,
* known constraints.

If the feature does not yet exist in the knowledge system, create its initial boundary.

---

## Phase 2 — Context Planning

Determine which knowledge sources may constrain the work.

Example:

```text
UI/UX: required
Architecture: required
Backend: not required
Data: not required
QA: required
Security: not required
Feature history: required
Code impact: required
```

---

## Phase 3 — Fan-Out

Run narrow resolvers in parallel.

Each returns structured, sourced evidence.

---

## Phase 4 — Fan-In

Synthesize findings.

The synthesis process should:

* remove redundancy,
* preserve provenance,
* reconcile overlapping findings,
* identify contradictions,
* rank relevance,
* surface missing information,
* and produce the smallest sufficient Context Artifact.

---

## Phase 5 — Implementation

Instantiate or continue the Feature Expert using the Context Artifact.

The Feature Expert:

* investigates,
* makes decisions,
* implements,
* tests,
* and records new knowledge.

---

## Phase 6 — Knowledge Update

Before QA, update:

* feature decisions,
* feature implementation notes,
* invariants,
* interfaces,
* edge cases,
* test map,
* history,
* relevant domain knowledge,
* specifications where appropriate,
* traceability references.

---

## Phase 7 — QA

An independent QA agent reviews:

```text
ticket
→ specifications
→ decisions
→ implementation
→ tests
→ documentation
```

QA produces a review artifact.

---

## Phase 8 — Remediation

If QA identifies an issue:

```text
QA Finding
    ↓
Feature Expert
    ↓
Implementation / Documentation Correction
    ↓
QA Re-review
```

---

## Phase 9 — Completion

The ticket is complete only when:

* implementation is accepted,
* tests pass,
* QA passes,
* feature knowledge is current,
* specification references are current,
* traceability is complete,
* history has been updated.

The agent may disappear.

The evidence remains.

---

# 19. Defects and Regressions

A defect should enter through the same system.

Example:

```text
BUG-844
Moving a folder causes the active file selection to disappear.
```

Traceability may reveal:

```text
BUG-844
    ↓ violates
FE-INVARIANT-007
Selection survives path changes.
    ↓ derived-from
ARCH-FILE-003
File identity is independent of path.
    ↓ implemented-by
workspaceFiles.ts
    ↓ previously-verified-by
test_file_move_preserves_selection
```

The Feature Expert can therefore begin with historical knowledge rather than rediscovering the feature.

The regression should also ask:

> Why did our existing evidence fail to detect this?

That answer becomes new durable knowledge.

---

# 20. Recommended Repository Strategy

Initially, the Domain Knowledge System should live in a **separate repository** from the application.

Example:

```text
my-application
my-application-knowledge
```

This provides several advantages.

### Portability

The knowledge system is independent of:

* IDE,
* agent framework,
* model provider,
* application repository structure.

### Persistence

Knowledge survives major application restructuring.

### Extensibility

The same methodology can be applied to additional projects without coupling it to one codebase.

### Auditability

Knowledge history has its own commit history.

### Cleaner separation

Application code remains application code.

Knowledge, reasoning, decisions, evidence, and roadmap information remain explicitly identifiable as a separate concern.

---

# 21. Application Revision Tracking

A separate repository introduces the possibility of drift.

Therefore, knowledge artifacts should record both:

```yaml
application_revision: <application commit SHA>
knowledge_revision: <knowledge commit SHA>
```

Where useful, completed ticket records should also contain:

```yaml
implemented_in:
  repository: my-application
  commit: <sha>

documented_in:
  repository: my-application-knowledge
  commit: <sha>
```

This preserves cross-repository traceability.

---

# 22. Future Co-Location

The knowledge repository should be designed so that it could eventually move into the application repository without restructuring the entire system.

The eventual convention could be:

```text
my-application/
├── src/
├── tests/
├── ...
└── .domain/
```

The same internal structure described below could live inside `.domain/`.

The decision to move it into the application should remain optional.

The architecture must not depend on co-location.

---

# 23. Proposed Repository Structure

```text
my-application-knowledge/
│
├── README.md
├── PHILOSOPHY.md
├── ROADMAP.md
├── CHANGELOG.md
│
├── specs/
│   ├── ui-ux/
│   ├── architecture/
│   ├── backend/
│   ├── data/
│   ├── qa/
│   ├── security/
│   └── accessibility/
│
├── domains/
│   ├── files/
│   │   ├── README.md
│   │   ├── knowledge.md
│   │   ├── interfaces.md
│   │   ├── history.md
│   │   │
│   │   └── features/
│   │       ├── project-file-explorer/
│   │       │   ├── README.md
│   │       │   ├── decisions.md
│   │       │   ├── invariants.md
│   │       │   ├── interfaces.md
│   │       │   ├── implementation.md
│   │       │   ├── tests.md
│   │       │   └── history.md
│   │       │
│   │       └── upload-file-selection/
│   │           └── ...
│   │
│   ├── subscriptions/
│   │   └── ...
│   │
│   └── authentication/
│       └── ...
│
├── artifacts/
│   ├── tickets/
│   ├── context/
│   ├── qa/
│   ├── investigations/
│   └── regressions/
│
├── indexes/
│   ├── specifications.yaml
│   ├── features.yaml
│   ├── dependencies.yaml
│   └── traceability.yaml
│
└── templates/
    ├── specification.md
    ├── domain.md
    ├── feature.md
    ├── decision.md
    ├── context-artifact.md
    ├── qa-review.md
    └── regression.md
```

The exact structure should be allowed to evolve.

The important part is the conceptual separation.

---

# 24. Feature Knowledge Template

Each feature should have a predictable structure.

```markdown
# Feature Name

## Purpose

What user or system capability this feature provides.

## Scope

What belongs to this feature.

## Out of Scope

What explicitly does not belong to this feature.

## Domain

Parent domain.

## Applicable Specifications

Canonical specification references.

## Dependencies

Other features, services, or domains required by this feature.

## Decisions

Important implementation decisions and reasons.

## Invariants

Things that must always remain true.

## Interfaces

Contracts exposed or consumed.

## Implementation Map

Relevant application locations.

## Test Map

Tests providing evidence for feature behavior.

## Edge Cases

Known unusual behavior.

## Known Limitations

Intentional constraints.

## History

Meaningful changes, regressions, migrations, and superseded decisions.
```

---

# 25. Decision Template

Decisions are one of the most important artifacts.

A decision should answer **why**.

```markdown
# FE-021 — Stable Identity for Explorer Selection

## Status

Accepted

## Context

The Project File Explorer must preserve selection when files are moved or renamed.

## Applicable Specifications

- ARCH-FILE-003
- UX-TREE-012

## Decision

Explorer selection is stored using stable file identity rather than path.

## Why

Paths are mutable while file identity is stable.

Using path as selection identity would violate ARCH-FILE-003 and cause
selection loss during move and rename operations.

## Implementation

- src/state/workspaceFiles.ts
- src/explorer/FileTree.tsx

## Verification

- test_file_move_preserves_selection
- test_file_rename_preserves_selection

## Consequences

The UI may display a changed path while retaining the same selected entity.

## Supersedes

None
```

---

# 26. Specification Template

Specifications should also have predictable structure.

```markdown
# UX-TREE-012 — Keyboard Navigation for Persistent Trees

## Status

Active

## Scope

Persistent hierarchical navigation surfaces.

## Rule

Persistent hierarchical trees must provide keyboard traversal.

## Applicability

Applies when:

- hierarchical navigation is persistent,
- nodes are directly interactive,
- keyboard access is expected.

Does not automatically apply to:

- temporary file-selection dialogs,
- flat lists,
- purely decorative trees.

## Rationale

Provides predictable and accessible navigation behavior.

## Verification Expectations

Implementations should include automated keyboard interaction coverage.

## Known Consumers

- Project File Explorer
- Repository Browser

## History

Created: ...
Last revised: ...
```

---

# 27. Context Artifact as a First-Class Artifact

Context artifacts should not be considered disposable prompts.

They are evidence of:

> What information was considered relevant when this implementation was made?

That makes them historically valuable.

A ticket should therefore retain its final Context Artifact after completion.

This allows future reviewers to compare:

```text
What was known then?
```

against:

```text
What is known now?
```

---

# 28. Changelogs and History

History should exist at multiple useful levels.

### Project

```text
CHANGELOG.md
```

Meaningful changes to the knowledge system itself.

### Domain

```text
domains/files/history.md
```

Major evolution of the Files domain.

### Feature

```text
domains/files/features/project-file-explorer/history.md
```

Feature-specific implementation evolution.

### Ticket

```text
artifacts/tickets/FILE-128/
```

Exact trace of a single implementation.

History should not duplicate Git.

Git answers:

> What changed?

Domain history should answer:

> What changed in our understanding or behavior, and why?

---

# 29. Orchestration Responsibilities

The workflow requires orchestration.

The orchestrator should enforce process rather than perform all reasoning itself.

It should ensure:

```text
Ticket classified
        ↓
Relevant knowledge domains identified
        ↓
Required resolvers executed
        ↓
Context Artifact assembled
        ↓
Feature Expert instantiated
        ↓
Implementation completed
        ↓
Knowledge updated
        ↓
Trace recorded
        ↓
QA executed
        ↓
Findings resolved
        ↓
Completion recorded
```

The orchestrator should also detect missing artifacts.

For example:

```text
Implementation changed but no decision updated.

New invariant introduced but no test exists.

Specification changed but downstream consumers were not reviewed.

Feature behavior changed but history was not updated.
```

---

# 30. Cost Model

Fan-out is not necessarily the cheapest execution strategy.

It is intentionally trading some compute for:

* parallelism,
* cleaner context,
* specialization,
* provenance,
* reduced context pollution,
* easier auditing,
* greater reproducibility,
* and improved reasoning quality.

Cost should be controlled through conditional fan-out.

Not every ticket needs every resolver.

A backend-only defect may require:

```text
Backend Specifications
Feature History
Code Impact
Tests
```

A new interactive navigation feature may require:

```text
UI/UX Specifications
Architecture Specifications
Accessibility Specifications
Feature History
Code Impact
Tests
```

The system should resolve what is needed before launching work.

---

# 31. Reuse and Caching

Because specifications are versioned, retrieval results can eventually be cached.

For example:

```text
Feature:
Project File Explorer

Specification dependencies:
UX-TREE-012 @ revision A
ARCH-FILE-003 @ revision C
QA-A11Y-008 @ revision B
```

If none of those references change, future context preparation can reuse substantial portions of previous discovery.

Fan-out therefore does not necessarily imply permanently high cost.

The trace itself can make future retrieval cheaper.

---

# 32. What the System Is Not

The Domain Knowledge System is not:

* a giant persistent chat,
* a dump of every conversation,
* an agent personality framework,
* a simulated corporate hierarchy,
* a replacement for source control,
* a replacement for tests,
* a second copy of the source code,
* a collection of prose with no references.

It is a structured, versioned, traceable knowledge layer describing **why and how the software exists in its current form**.

---

# 33. Foundational Rules

The initial implementation should preserve these rules.

### Rule 1

**Durable knowledge is more important than durable conversation.**

### Rule 2

**Agents may disappear; evidence must not.**

### Rule 3

**Specifications define reusable system rules.**

### Rule 4

**Domains contain durable knowledge about meaningful areas of the application.**

### Rule 5

**Features document how specific product behavior applies the relevant specifications.**

### Rule 6

**Feature Experts are instantiated from durable context rather than treated as permanent sources of truth.**

### Rule 7

**Knowledge belongs at the narrowest scope where it is universally true.**

### Rule 8

**Feature knowledge references specifications rather than duplicating them.**

### Rule 9

**Context discovery should fan out narrowly and fan in into one coherent artifact.**

### Rule 10

**Implementation agents should operate from the smallest sufficient authoritative context.**

### Rule 11

**Every important piece of retrieved knowledge should preserve provenance.**

### Rule 12

**Every meaningful implementation decision should be traceable to its cause.**

### Rule 13

**Every important behavioral claim should have corresponding verification evidence where practical.**

### Rule 14

**QA evaluates the complete trace, not merely the code.**

### Rule 15

**General discoveries should be promoted into specifications; feature-specific discoveries remain local.**

### Rule 16

**The knowledge topology should increasingly resemble the software topology.**

---

# 34. Completion Definition

A feature ticket is not fully complete merely because the code works.

Completion means the durable system can answer:

```text
What did we build?

Why did we build it this way?

Which specifications governed it?

Which decisions were made?

Where is it implemented?

What must remain true?

How was it tested?

How was it reviewed?

What other parts of the application depend on it?

What knowledge changed because of this work?
```

If those questions can be answered without recovering the original chat, the system has succeeded.

---

# 35. Working Name and Storage Convention

For now:

## System Name

**Domain Knowledge System**

## External Repository

```text
<project>-knowledge
```

Example:

```text
my-application-knowledge
```

## Potential Future In-Repository Location

```text
.domain/
```

The name `.domain` is intentionally implementation-agnostic.

It does not belong to:

* Claude,
* Cursor,
* ChatGPT,
* a particular IDE,
* or a particular orchestration framework.

It belongs to the project.

The directory represents:

> **The durable knowledge required to understand, modify, verify, and trace this system.**

If a better name emerges later, the architecture should make renaming inexpensive.

The structure and philosophy are more important than the label.

---

# 36. Initial Implementation Goal

The first version does not need to implement the full graph or extensive automation.

A useful V1 would support:

1. a separate knowledge repository,
2. a small set of specifications,
3. domain folders,
4. feature folders,
5. explicit decisions,
6. specification references,
7. ticket-specific Context Artifacts,
8. fan-out context retrieval,
9. one primary Feature Expert,
10. independent QA review,
11. changelog/history updates,
12. application and knowledge revision tracking.

That is enough to test the central hypothesis:

> **Can we make agentic software development more reliable by preserving the reasoning and evidence around each feature rather than preserving the agents or conversations that produced it?**

If the answer is yes, everything else can grow from that foundation.