# Investigation sequence

> **What this is:** how the method in [SKILL.md](./SKILL.md) actually operates — the eight steps as a sequence, with the returns drawn in. The steps are ordered by dependency, so the value of the diagram is the **backward** arrows: where a later step flips an earlier answer and forces its dependents to be redone.
>
> **Syntax constraints inside the mermaid block** — use `—` or `·` to set off an aside instead of any of these:
>
> - **No parentheses** — LucidChart's mermaid parser rejects them.
> - **No semicolons** — mermaid reads `;` as a statement separator, so a note ends mid-sentence and the remainder is parsed as a new statement.
> - **No `#`** — it opens an HTML entity code.

```mermaid
sequenceDiagram
    participant E as Evidence
    participant PC as Problem Check
    participant CL as Class + wedge
    participant AC as Contract
    participant SOL as Solution
    participant A as Assumptions
    participant O as Open variables
    participant R as Report

    Note over E,R: Standing disciplines — gather evidence before asking · every claim falsifiable · coverage ledger consulted before any branch
    Note over E,R: Dependency order — never skip ahead · when a checkpoint flips an earlier answer, redo its dependents first

    Note over E,R: Step 1 — Collect the raw facts · ground downward first
    E->>E: name real instances · one plain sentence each · the date it bites
    E->>PC: the problem as stated
    PC->>PC: Asked / Answered / Should-ask · Conflation · Thin · Off
    PC-->>E: conflated problems separated into distinct problems
    PC->>A: thin terms and unsupported claims
    PC->>O: framing questions no evidence can answer

    Note over E,R: Step 2 — Classify the problem · provisional
    E->>CL: derive the class from the instances, not the framing
    CL->>CL: assumed class vs derived class
    alt they differ
        Note over CL: stop and flag loudly — a reclassification is a major finding, not a footnote
    end
    CL->>CL: find the wedge inside the class

    Note over E,R: Step 3 — Lock the contract before any solutioning
    CL->>AC: what the class implies for the solution space
    AC->>AC: acceptance criteria, each checkable · non-goals · framing drift

    Note over E,R: Step 4 — Trace why it exists, then re-check the class
    E->>A: origin evidence from the primary source
    A->>A: confirm or revise each assumption against that evidence
    A->>CL: checkpoint — re-confirm the class against root cause
    alt the class flips
        CL->>CL: redo the wedge
        CL->>AC: redo the acceptance criteria
        Note over CL,AC: cheap here · churn in everything after
    end

    Note over E,R: Step 5 — Propose, compare, stress-test
    CL->>SOL: the confirmed class
    AC->>SOL: the target to test against
    SOL->>SOL: alternatives considered, and why each was rejected
    SOL->>AC: coverage per criterion — covered / needs proof / documented / gap
    SOL->>SOL: scale · generalization · fit · adjacent · sufficiency · feedback speed
    SOL->>SOL: actor / action / moment · the 30-second flip-side story

    Note over E,R: Step 6 — Build the validation plan
    SOL->>R: happy path, step by step
    SOL->>R: negative and inferred paths — what must fail visibly

    Note over E,R: Step 7 — Reconcile open questions against the evidence
    O->>O: classify each on the fact-vs-decision axis
    alt discoverable in the evidence
        O->>E: go trace it now — code, source, observed behavior
        E-->>A: moved to the assumptions ledger with its finding
    else a genuine decision
        O->>O: stays open, with an owner
        Note over O: prove it unanswerable — cite the missing seam, absent field, indistinguishable state
    end

    Note over E,R: Step 8 — Emit the report · the verdict is written last
    CL->>R: assumed vs confirmed class, and the step it flipped
    AC->>R: problem statement · acceptance criteria · non-goals
    A->>R: assumptions ledger, each with status and how to confirm it
    O->>R: open variables, each with an owner
    SOL->>R: solution, stress-test, alternatives
    R->>R: verdict · disposition · what this is not yet
```

## Where the returns are

| Return | Trigger | What gets redone |
| --- | --- | --- |
| Problem Check → Step 1 | conflation found | the problem list splits; each distinct problem restated |
| Step 4 checkpoint → Step 2 | class flips against root-cause evidence | the wedge, then the acceptance criteria |
| Step 5 → Step 3 | a criterion has no coverage | the criterion, or the solution that was supposed to meet it |
| Step 7 → Step 1 | an open question turns out discoverable | trace it now; it becomes an assumption with a finding, not a question |
