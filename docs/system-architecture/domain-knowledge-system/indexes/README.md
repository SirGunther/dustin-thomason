# indexes

Reverse lookups. Create one only when reading folder and file names stops being
enough, which happens when the spec tree grows past what a reader scans in one pass.

    specifications.yaml    rule to the nodes that cite it
    features.yaml          question to the node that owns the answer

`specifications.yaml` should be derived from the Governs field of each node rather
than authored. A hand-maintained reverse index drifts the moment someone adds a
consumer without updating the rule.

Known Consumers in a spec file is the exception and stays curated. A derived list
gives every consumer, unranked, which answers impact analysis. An integration needs
the one example worth copying, and that is a judgment.
