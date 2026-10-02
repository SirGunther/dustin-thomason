# Review Instructions

### Original Ticket

### Ledge Location

Review the decisions made in the ledger

---

### Spec to Review

#### Determine if the spec:

- follows the ticket
- has scope creep 
- is overbuilt 
- is appropriate for the changes

---

## Validate integration for PR reviews

attached is the agents last response

Determine if the implementation is accurate based on the original ticket, codebase, and associated artifacts. Importantly, ensure that the review and implementation are within scope.

To ground the review, after ingesting the docuementation, establish WHY the ticket was written, HOW it was addressed, and ultimately the subsequent review will determine if WHAT was done was sufficient and within scope to resolve.

Additionally, compare against the `C:\..\<system updated>\.cursor\rules` to ensure best practices for the system were followed.

Write out each finding here as a checklist in the chat, review the relevant context, and provide evidence in the chat demonstrating that finding.

Assertions without that evidence, will be prompted to review the finding again.

Ignore running test suites/linting/etc. these were already performed.
Decisions about implementation related to product or spec or smoke testing with live data are irrelevant for these purposes.

We only care that the implementation was done correctly.

You will also validate the PR, [pr-review-patterns.md](c:/dustin-thomason/docs/reviewers/pr-review-patterns.md) and if there are any violations that pertain to this ticket directly. [https://github.com/planetdepos/atlas-front-end/pull/566](https://github.com/planetdepos/atlas-front-end/pull/566) is an example of a good PR.

#### Note

You don't need to call out decisions about implementation related to product or spec or smoke testing with live data, irrelevant for these purposes, we are only looking at what has been implemented thus far. If there are inconsistency between artifacts, a section to note this is acceptable, but should not be a blocker to determining if the implementation is correct.

---

Commenting check. Enumerate ALL comments that were added, compare against the C:\dustin-thomason\docs\reviewers doc and the rules for commenting. Determine if the commment is appropriate. Create a table. We will determine how to handle clean up. IGNORE SPEC FILES.

---

Last report on status of the update. If everything looks good, let's go ahead and commit and push.
And make sure there is a PR ready, look at INT-138 as well how that looks, that's how we want this one to look as well.
C:\dustin-thomason\docs\reviewers