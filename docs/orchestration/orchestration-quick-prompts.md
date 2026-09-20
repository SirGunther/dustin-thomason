# Orchestration Quick Prompts

## Ingestion Phase

```
### Worklists Item
@dustin-thomason/agents/rules/worklists-card-sync.md
Card Id:

### Original Ticket
Ticket name:


### Repository Scope


### Context
C:\dustin-thomason\.agents
C:\dustin-thomason\agents\skills\orchestrate\SKILL.md

### Ensure all related repositories are
- loaded
- on main (if not otherwise specified)
Stash any work on the branches if there is any
```

---

## Review Spec Plan

The purpose here is to review the spec plan before building the spec artifacts and spec that will be submitted via PR.

### Provide

* plan to review
* original ticket

#### Prompt

```
### Please Review


### Original Ticket


Determine if the spec plan is overbuilt, or appropriate for the changes.
```

---

## Review Spec and Artifacts

The purpose here is to review the spec and the associated artifacts. Only the spec will submitted as a PR, artifacts are for posterity.

### Provide

* document repo

#### Prompt

```
### Please Review


### Original Ticket


Determine if the spec is written accurately based on the original ticket, codebase, and associated artifacts. Importantly, ensure that the spec stays within scope.
```

---

### Follow up

```
Review of your Spec and Artifacts, please update accordingly

```

---

## Implement to validate spec before review by other dev

The purpose here is to ensure the spec is fully accurate. We must test what we think we have accomplished. We then push anything that was incorrect about the spec. Only then can we tag a reviewer.

#### Prompt

```
### Validate spec with integration

This step may seem counterintuitive, but helps us work towards two separate goals simultaneously. 
1. We are able to get a jump start on implementation
2. We validate that the spec was written accurately

This is not validation that the spec is correct in the terms of the orchestration layer, rather, we are testing the specs correctness. The benefit may be that we are one step ahead of a reviewers approval, ultimately saving us time.

Ensure that we are up to date with main, stash the old, then open a new branch, this will be our implementation branch. 

Begin planning with Phase 4.
```

---

## Review Implementation

The purpose is to ensure that the implementation was done correctly and adheres to common incorrect imlpementations. Typically done by a different agent (peer review), self review often misses mistakes.

### Prompt

```
## Validate integration for PR reviews

### Please Review


### Branch


Determine if the implementation is accurate based on the original ticket, codebase, and associated artifacts. Importantly, ensure that the review and implementation are within scope.

To ground the review, after ingesting the docuementation, establish WHY the ticket was written, HOW it was addressed, and ultimately the subsequent review will determine if WHAT was done was sufficient and within scope to resolve.

Additionally, compare against the `C:\..\<system updated>\.cursor\rules` to ensure best practices for the system were followed.

Write out each finding here as a checklist in the chat, review the relevant context, and provide evidence in the chat demonstrating that finding.

Assertions without that evidence, will be prompted to review the finding again.

Ignore running test suites/linting/etc. these were already performed.
Decisions about implementation related to product or spec or smoke testing with live data are irrelevant for these purposes.

We only care that the implementation was done correctly.

You will also validate the PR, [pr-review-patterns.md](c:/dustin-thomason/docs/reviewers/pr-review-patterns.md) and if there are any violations that pertain to this ticket directly. https://github.com/planetdepos/atlas-front-end/pull/566 is an example of a good PR.
```
