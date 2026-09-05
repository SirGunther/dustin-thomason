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


Determine if the spec is written accurately based on the original ticket, codebase, and associated artifacts.
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
```
