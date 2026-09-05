# {{Area or Feature}}

## Reviewed against

    application_revision: {{sha}}
    knowledge_revision: {{sha}}

Both are required. A node whose application revision falls behind while its
implementation sites changed is suspect, which is the only available signal that a
decision quietly stopped being true.

## Governs

Per rule: the ID, its file, the revision this node was last reviewed against, and
why it was selected (§11).

    - id: {{ID}}
      source: specs/{{discipline}}/{{subject}}.md
      revision: {{sha at last review}}
      reason_selected: >
        {{why this rule bites on this node, not what the rule says}}

## Decisions

What was decided, why, and what was rejected. The rejected alternative is the part
that appears in no test and no code.

    {{decision}}
    Why: {{reason}}
    Rejected: {{alternative}}, because {{reason}}
    Supersedes: {{prior decision, or none}}

## Invariants

Each statement paired with the test that proves it. An invariant with no named test
is an unverified claim.

    {{what must always remain true}}
    Proven by: {{test name or file}}

## Not owned

What a sibling node owns instead, and which node that is. This is what keeps an
implementation from landing in the wrong place.

## Affects

Sibling nodes whose invariants this node's behavior can move (§16, depends-on). A
node touched by a change but absent from the context artifact is a recorded
retrieval miss and becomes an entry here.

## History

Failed attempts and abandoned approaches. Regressions, with the invariant each one
violated and why existing evidence failed to detect it (§19). Change lists stay in
git; this section holds what git cannot show.
