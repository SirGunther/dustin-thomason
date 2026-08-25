# User Validation Status Template

Use this template for a version-specific review. Every table row must map one-to-one to an identically numbered body objective. Every body objective must identify its directly affected or validation-relevant files with concise Markdown links. Do not add standalone status rows for behavior that lacks a corresponding objective header; place narrower checks inside the matching objective's optional Validation Details subsection.

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

## Affected File Link Rules

Every body objective must place a concise `Files:` line immediately below its `### D<number>: <objective>` heading.

Required layout:

`Files: [Application shell](../../app.js), [UI state](../../ui/ui-state.mjs), [Focused regression](../../tests/example.test.mjs)`

1. Use standard Markdown links so every listed file can be opened directly from the rendered review.
2. Resolve each relative link from the generated review artifact in `<project-root>/docs/review/`.
3. Use short descriptive labels such as `Application shell`, `UI state`, or `Focused regression`; do not expose a long raw path as the label.
4. List only files directly affected by the objective or needed to validate it. Do not reproduce the complete implementation diff beneath every objective.
5. Separate multiple links with commas and keep the complete file list on one line when practical.
6. Verify every local link target exists when the review is created or updated.
7. When an objective genuinely has no applicable local file, write `Files: N/A - <concise reason>` rather than inventing a link.

## Validation Detail Rules

Every `#### Validation Details` section must begin with a **Validation Objective** of five to seven words. A Validation Objective is subordinate to the enclosing `D<number>` objective and names the specific outcome tested by the following checks.

Do not copy or lightly rephrase the enclosing objective header. The Validation Objective must narrow that objective into a concrete validation focus without restating an individual `Prove` item.

Follow the Validation Objective with a one- or two-sentence summary explaining how this validation focus supports the enclosing D-objective and what the checks establish together.

Every validation checkbox must begin with a clear objective that states what the reviewer is trying to prove. The exact word `Prove` is required so the purpose of the check remains explicit. Nest the action and expected result beneath that objective so the reviewer can quickly understand the goal, perform the check, and determine whether it passed.

Required layout:

```markdown
#### Validation Details

**Validation Objective:** <five-to-seven-word specific validation focus>

<One or two sentences explaining how this validation focus supports the enclosing D-objective and what the checks establish together. Do not restate an individual Prove item.>

Validation setup: <exact prerequisite when required>.

- [ ] **Prove:** <specific behavior or outcome the reviewer must establish>.
  - **Action:** <specific user action, command, request, input, or selection>.
  - **Expected:** <specific visible, returned, or persisted result>.
```

UI example:

```markdown
- [ ] **Prove:** A logged-item source range is visible in its transcript context.
  - **Action:** Select a logged-item source range.
  - **Expected:** The transcript scrolls to its first contributing row and highlights every row in the exact referenced range.
```

API-only example:

```markdown
- [ ] **Prove:** A firm response includes its linked seated contacts.
  - **Action:** Load the linked fully seated contact-firm fixture and send `GET /api/firms/<fixture-id>` with the documented test client.
  - **Expected:** The response is HTTP 200; `id`, `name`, `primary_contact_id`, and `seat_count` match the fixture, and `contacts` contains the linked seated contacts.
```

1. Cover every requirement with at least one validation checkbox. Do not leave a requirement without a concrete way to prove it.
2. Write each `Prove` statement as a concise, human-readable objective describing the behavior or outcome that determines success. Do not use the action itself as the objective.
3. Prefer proof that is directly observable in the product UI. When data is meant to populate a screen, ask the reviewer to confirm the specific data is visible and correct on that screen rather than inspect the network tab, HTTP traffic, developer tools, logs, or internal data flow.
4. Use technical validation only when the behavior has no user-visible result or when the requirement specifically concerns an API, integration, persistence boundary, or other non-UI contract. Do not require technical inspection when the same outcome can be proved from the user experience.
5. Keep validation fast and focused. Include only the minimum action and observation needed to prove the objective; move implementation diagnostics and exploratory troubleshooting out of the hands-on checklist.
6. Identify the exact control label, page, command, endpoint and method, test record, fixture, input, or sequence the reviewer must use.
7. State any required setup immediately beneath `#### Validation Details` as `Validation setup: <exact prerequisite>`. Include the startup command, URL, account or role, seed data, fixture link, or initial state when it is not already obvious.
8. Make the expected result directly observable. Name the visible state, message, navigation, response status, required fields and values, persisted record, or other evidence that determines pass or fail.
9. Do not use vague criteria such as `works correctly`, `all fields are populated`, `returns the right data`, or `looks good`. Name the fields and conditions or link the governing schema or fixture and identify the specific values that must match.
10. Keep one coherent proof objective and one supporting action-result pair per checkbox. Split unrelated behaviors into separate checks so a partial result can be recorded accurately.
11. Write the instructions for the actual reviewer. Do not assume they know an internal tool, fixture ID, route, environment, or prerequisite that the review does not identify.
12. Automated tests may support readiness, but they do not replace a hands-on checkbox. When a check genuinely requires a technical client, provide the exact runnable command or a direct link to a prepared request or test fixture.
13. If the action cannot be performed with currently available access or data, identify the missing dependency and use `Blocked`; do not write an unexecutable validation step.

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
10. Link navigation to the complete renderer-generated heading slug, including both the identifier and objective title.
11. Link every table identifier to its complete objective slug, such as `[D1](#d1-five-to-seven-word-objective-header)`.
12. Place a **Return to User Validation Status** navigation control at the end of every objective section.
13. Update the table link whenever an objective heading changes because its generated slug changes with it.
14. Include the required concise Markdown-linked `Files:` line beneath every objective heading.
15. Begin every Validation Details section with a five-to-seven-word **Validation Objective** and a one- or two-sentence summary, then format every checkbox as an explicit **Prove** objective with indented **Action** and **Expected** sub-points, with exact setup when required.

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
- **N/A:** The review is retained for reference but has no applicable Objectives.

## User Validation Status

Each row maps one-to-one to the identically numbered objective in this document. **Passed** means the objective met its expectation with applicable evidence. **Failed** means the expected behavior did not occur. **Blocked** means the objective could not be evaluated because a required dependency failed. **Pending** means the objective is ready but has not yet been evaluated. **N/A** means the objective does not apply and requires no action.

| Id     | Item                                                      | Status  | Next step                               | Notes |
| ------ | --------------------------------------------------------- | ------- | --------------------------------------- | --------------------------------------- |
| **[D1](#d1-five-to-seven-word-objective-header)** | **Five To Seven Word Objective Header** Brief description. | Pending | State the next concrete validation step. |
| **[D2](#d2-another-version-specific-objective-header)** | **Another Version Specific Objective Header** Brief description. | Pending | State the next concrete validation step. |

## Review Summary

Summarize whether this version met expectations, identify any release-level failure or dependency block, and point to the next version or ticket when corrective work exists. Do not contradict the item statuses above.

### D1: Five To Seven Word Objective Header

Files: [Application file](../../path/to/file), [Focused validation](../../tests/path/to/file.test.js)

#### Problem

- **Current Behavior(s):** Describe what existed or occurred before the change.
- **Expected Behavior(s):** Describe the observable result that defines success.

#### Requirement(s)

- State what must be true to move from the current behavior to the expected behavior.

#### Solution(s)

- State exactly what changed and why it satisfies the requirement.

#### Validation Details

**Validation Objective:** <five-to-seven-word specific validation focus>

<One or two sentences explaining how this validation focus supports the
enclosing D-objective and what the checks establish together. Do not restate an
individual Prove item.>

Validation setup: Start the project with `<exact command>`, open `<exact URL>`, and load `<named test state or fixture>`.

- [ ] **Prove:** `<specific user-visible behavior or outcome>` is available to the reviewer.
  - **Action:** Select `<exact control label>` and provide `<specific input>`.
  - **Expected:** `<specific visible state, message, or persisted value>` appears.
- [ ] **Prove:** `<next distinct user-visible behavior or outcome>` occurs.
  - **Action:** Perform `<next exact reviewer action>`.
  - **Expected:** `<observable result that determines pass or fail>` occurs.

[**↑ Return to User Validation Status**](#user-validation-status)

---

### D2: Another Version Specific Objective Header

Files: [Affected component](../../path/to/another-file), [Validation fixture](../../tests/fixtures/example.json)

#### Problem

- **Current Behavior(s):** Describe the version-specific problem.
- **Expected Behavior(s):** Describe the version-specific success condition.

#### Requirement(s)

- State the requirement.

#### Solution(s)

- State the implemented solution.

#### Validation Details

**Validation Objective:** <five-to-seven-word specific validation focus>

<One or two sentences explaining how that validation focus supports the
enclosing D-objective and what the checks establish together. Do not restate an
individual Prove item.>

Validation setup: Load [Named validation fixture](../../tests/fixtures/example.json) and start `<service>` with `<exact command>`.

- [ ] **Prove:** The API returns `<specific contract behavior or outcome>`.
  - **Action:** Send `<METHOD> <endpoint>` using `<exact client, command, or linked prepared request>`.
  - **Expected:** The response is HTTP `<status>` and `<named fields>` match the linked fixture values.

[**↑ Return to User Validation Status**](#user-validation-status)
