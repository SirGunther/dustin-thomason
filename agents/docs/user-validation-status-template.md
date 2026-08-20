# User Validation Status Template

Use this template for a version-specific review. Every table row must map one-to-one to an identically numbered body objective. Do not add standalone status rows for behavior that lacks a corresponding objective header; place narrower checks inside the matching objective's optional Validation Details subsection.

## Canonical Template Location

The canonical template is maintained at:

`C:\dustin-thomason\agents\docs\USER-VALIDATION-STATUS-TEMPLATE.md`

Update this canonical file when the review standard changes. Do not treat a generated project review as the source template.

## Generated Review Placement

Place each generated review inside the applicable project:

`<project-root>/docs/review/`

For projects stored in the Dustin Thomason repository, this will usually resolve to:

`C:\dustin-thomason\<project>\docs\review\`

Create the `docs/review` folder when it does not exist. If a project already has a stricter documentation convention, follow it while retaining a dedicated `review` folder beneath the project's documentation area.

## Filename And Version Convention

The project version must appear in both the review filename and the document itself. Use the exact released or proposed project version; do not assign a version that is not supported by the manifest, package metadata, tag, ticket, or user direction.

With a ticket:

`v<version>-<ticket-id>-<ticket-name>-validation-review.md`

Example:

`v1.11.2-PD-482-floating-slate-initializer-validation-review.md`

Without a ticket:

`v<version>-<change-name>-validation-review.md`

Example:

`v1.11.2-floating-slate-initializer-validation-review.md`

Filename rules:

1. Prefix the version with lowercase `v`.
2. Preserve the official ticket ID, such as `PD-482`.
3. Convert the ticket or change name to concise lowercase kebab-case.
4. End every generated filename with `-validation-review.md`.
5. Do not put `Passed`, `Failed`, `Blocked`, `Pending`, `Mixed`, or another mutable review status in the filename.
6. Do not overwrite or rename an earlier version's review when a corrective version is created.

## Document Title Convention

With a ticket:

`# <Project> v<version> - <ticket-id>: <ticket name> - Validation Review`

Without a ticket:

`# <Project> v<version> - <change name> - Validation Review`

The title, Document Control version, filename version, changelog version, and underlying project metadata must agree.

## Ticket And Cross-Reference Rules

1. Include both the ticket ID and ticket name when a ticket exists.
2. Use `N/A` for both ticket fields when no ticket exists; do not invent one.
3. Link the applicable changelog entry to the generated review artifact.
4. Link the review back to its changelog, ticket, superseded review, and corrective follow-up when those references exist.
5. Create a new review artifact for a corrective version and preserve the prior version's original outcome.
6. Point failed or blocked Next steps to the specific follow-up version, ticket, or objective whenever known.

## Review Construction Rules

1. Use sequential identifiers beginning with `D1`.
2. Copy each objective header into the matching Item cell exactly.
3. Include exactly one primary status row per body objective and no orphan rows.
4. Use **Passed** only with applicable evidence, **Failed** when the expected result did not occur, **Blocked** only when a required dependency failed, **Pending** when testing is ready but incomplete, and **N/A** when the objective does not apply.
5. Give every row a concrete next step. Use `None.` only when no further action is warranted.
6. Put narrower feature checks beneath their matching objective rather than creating unrelated table rows.
7. Keep objective headers between five and seven words, excluding the `D` identifier.
8. Record evidence without converting assumptions into completed validation.
9. Use the overall **Mixed** status only in Document Control when applicable objectives have materially different outcomes and no single release-level result describes the review accurately.

---

# [Project] v[Version] - [Ticket ID]: [Ticket Name] - Validation Review

If no ticket exists, replace the title with:

`# [Project] v[Version] - [Change Name] - Validation Review`

This artifact records the problems, requirements, solutions, and validation status for this specific project version.

## Document Control

| Field | Value |
| ----- | ----- |
| Project | `[Project name]` |
| Version | `v[version]` |
| Ticket ID | `[Ticket ID or N/A]` |
| Ticket name | `[Ticket name or N/A]` |
| Overall review status | `[Passed / Failed / Blocked / Pending / Mixed / N/A]` |
| Review date | `[YYYY-MM-DD]` |
| Reviewed by | `[Name, agent, or team]` |
| Changelog | `[Relative link to changelog entry]` |
| Supersedes | `[Relative link or N/A]` |
| Follow-up | `[Relative link, version, ticket, or N/A]` |

Choose the overall review status using the complete version outcome:

- **Passed:** All applicable release objectives passed.
- **Failed:** A release-level or critical expectation failed.
- **Blocked:** The review could not proceed because a required dependency failed.
- **Pending:** Validation remains incomplete and no release-level failure has been established.
- **Mixed:** Material objectives have different outcomes and no single release-level result is accurate.
- **N/A:** The review is retained for reference but has no applicable validation objectives.

## User Validation Status

Each row maps one-to-one to the identically numbered objective in this document. **Passed** means the objective met its expectation with applicable evidence. **Failed** means the expected behavior did not occur. **Blocked** means the objective could not be evaluated because a required dependency failed. **Pending** means the objective is ready but has not yet been evaluated. **N/A** means the objective does not apply and requires no action.

| Id     | Item                                                      | Status  | Next step                               |
| ------ | --------------------------------------------------------- | ------- | --------------------------------------- |
| **D1** | **Five To Seven Word Objective Header** Brief description. | Pending | State the next concrete validation step. |
| **D2** | **Another Version Specific Objective Header** Brief description. | Pending | State the next concrete validation step. |

## Review Summary

Summarize whether this version met expectations, identify any release-level failure or dependency block, and point to the next version or ticket when corrective work exists. Do not contradict the item statuses above.

### D1: Five To Seven Word Objective Header

Files: `path/to/file`

#### Problem

- **Current Behavior(s):** Describe what existed or occurred before the change.
- **Expected Behavior(s):** Describe the observable result that defines success.

#### Requirement(s)

- State what must be true to move from the current behavior to the expected behavior.

#### Solution(s)

- State exactly what changed and why it satisfies the requirement.

#### Validation Details

- [ ] Add narrower checks only when they belong to D1.
- [ ] Record the evidence required to update D1's table status.

---

### D2: Another Version Specific Objective Header

Files: `path/to/another-file`

#### Problem

- **Current Behavior(s):** Describe the version-specific problem.
- **Expected Behavior(s):** Describe the version-specific success condition.

#### Requirement(s)

- State the requirement.

#### Solution(s)

- State the implemented solution.

#### Validation Details

- [ ] Add any D2-specific validation checks here.
