# {{ID}}: {{Subject}}

One rule per entry. The file name states the subject, because the file name is what
acceptance criteria are matched against. `{{ID}}` is derived from the file's path;
see [identifiers.md](../identifiers.md). Do not assign an ID by hand.

## Status

Draft | Active | Withdrawn | Superseded by {{ID}}

A withdrawn rule stays in the directory listing rather than being deleted, which
records that the subject was considered and rejected.

## Scope

The class of thing this governs, stated in one sentence.

## Rule

The constraint. Stated so it can be violated, which is what makes it checkable.

## Applicability

**Applies when:**

- {{condition}}

**Does not apply to:**

- {{condition}}

This section decides whether the rule reaches a given feature. A rule without it is
either never selected or selected for every adjacent task.

## Rationale

Why the rule exists. What goes wrong without it.

## Verification expectations

What evidence an implementation owes. Name the kind of coverage, not a specific test.

## Known consumers

Features already implementing this rule. Curated, not exhaustive: name the one worth
copying first.

- `domains/{{area}}/features/{{feature}}.md`: {{why this one is the example}}

An entry with no consumers is a rule with no proven implementation. Say so here.

## History

Created: {{date}}. Revised: {{date}}, {{what changed and why}}.
