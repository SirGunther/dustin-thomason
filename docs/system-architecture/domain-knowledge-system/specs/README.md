# specs

A specification is a reusable rule, constraint, convention, or expectation for the
system (§3.1). Specifications are authoritative: they define how the system is
expected to behave or be built.

## Naming is the retrieval mechanism

One subject per file. The file name states the subject. Acceptance criteria are
matched against these names, so a rule placed in a file whose name does not announce
it will never be found.

    specs/ui-ux/overlays.md    a criterion about an unrequested surface finds this
    specs/ui-ux/misc.md        nothing will ever find this

## Identifiers

Every rule file has an ID derived from its path: strip `.md`, uppercase the stem,
keep every hyphenated word, and prefix it with the discipline code below. Full
derivation rule and examples are in [identifiers.md](../identifiers.md).

| Folder | Prefix |
| --- | --- |
| `ui-ux` | `UX` |
| `accessibility` | `A11Y` |
| `architecture` | `ARCH` |
| `backend` | `BE` |
| `data` | `DATA` |
| `security` | `SEC` |
| `qa` | `QA` |

No sequence number is added to a rule ID. One file holds exactly one rule. A second
rule about a related subject is a second file, with its own name and its own ID.

## Stubs

Every candidate subject ships as a file carrying `Status: Not written` and a one
line scope. The file exists so its name appears in a directory listing, which is
what criteria are matched against, and the scope line is what separates near
neighbors such as overlays, toasts, and tooltips.

Selecting a stub is not a failure of the pull. It is the pull working: the report
names it, and that is how a missing rule becomes visible instead of being an absence
nobody noticed. Sorting selected stubs by how many criteria depend on them gives the
order to write rules in, and `indexes/specifications.yaml`'s `entries_unwritten`
list is what produces that ranking.

A stub's ID exists from the moment its file exists, since the ID is derived from the
path and needs no written content. A node may cite a stub's ID before the rule is
written.

## Withdrawal, not deletion

A rule that no longer applies is marked `Status: Withdrawn`, not deleted. The file
stays in the listing, which records that the subject was considered and rejected
rather than never considered. Deleting a rule file is permitted only during
instantiation, before any node can have cited it.

## Entry shape

A written rule follows [spec-entry.template.md](../templates/spec-entry.template.md):
ID, Status, Scope, Rule, Applicability, Rationale, Verification Expectations, Known
Consumers, History.

Two of those sections do the work during an integration. **Applicability** states
when the rule governs and when it does not, which keeps a rule from being pulled for
every adjacent task. **Known Consumers** names the features already implementing the
rule, which is how an implementer finds a working example instead of inventing a
second pattern.

## When a rule belongs here rather than in a feature node

Two or more consumers, behaving consistently. One instance is feature knowledge and
belongs in that feature's Decisions until a second consumer appears (§4). If two or
more exist and behave inconsistently, write the rule and list the inconsistent
features as violations requiring review (§15).
