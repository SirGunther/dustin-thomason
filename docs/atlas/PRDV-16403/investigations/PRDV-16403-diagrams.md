# Diagrams — atlas/PRDV-16403

Companion to [PRDV-16403-investigation.md](./PRDV-16403-investigation.md), which links here from §5 rather than embedding. Every diagram answers a named question; syntax follows the gotchas in `current-vs-target-diagram.md` (no colons in edge labels, no raw angle brackets, quoted node labels).

---

## Current vs target

**Question it answers:** what actually has to be built, given that the panel, the context and the data all already exist?

```mermaid
flowchart LR
    subgraph RB["RB9 - system of record"]
        RB1["Contacts.Warning"]
        RB2["Firms.Warning"]
        RB3["Cases.Warning"]
        RB4["Cases.RemarksHTML"]
    end

    subgraph CAL["callisto-back-end"]
        C1["contacts.warning<br/>NOT NULL varchar"]
        C2["firms.warning<br/>NOT NULL varchar"]
        C3["cases.warning<br/>nullable varchar"]
        C4["cases.remarks_html<br/>nullable text"]
        NEW1["NEW - AccessManagerWarningsRepository"]
        NEW2["NEW - FetchAccessManagerWarningsTS"]
        NEW3["NEW - FetchAccessManagerWarningsAction<br/>plus mapper, empty to null"]
    end

    subgraph ATL["atlas-front-end"]
        A1["AccessManagerOverlay.vue<br/>EXISTS - has contactId and proceedingId"]
        OLD["L333-335 placeholder p<br/>warningsPlaceholder"]
        NEW4["NEW - useAccessManagerWarnings"]
        NEW5["NEW - RbWarningsPanel<br/>plus inner scroll container"]
    end

    RB1 -->|"replicated - PRDV-16391 and earlier"| C1
    RB2 -->|"replicated"| C2
    RB3 -.->|"awaiting PRDV-16392 mapping"| C3
    RB4 -.->|"awaiting PRDV-16392 mapping"| C4

    C1 --> NEW1
    C2 --> NEW1
    C3 --> NEW1
    C4 --> NEW1
    NEW1 --> NEW2 --> NEW3
    NEW3 -->|"new HTTP surface"| NEW4
    NEW4 --> NEW5
    A1 --> NEW5
    OLD -->|"REMOVED"| NEW5

    classDef exists fill:#e8f0e8,stroke:#4a7,stroke-width:1px
    classDef new fill:#fff4e0,stroke:#d92,stroke-width:2px
    classDef gone fill:#f3e3e3,stroke:#b55,stroke-dasharray:4 3
    classDef pending fill:#eee,stroke:#999,stroke-dasharray:4 3
    class RB1,RB2,C1,C2,A1 exists
    class C3,C4 pending
    class NEW1,NEW2,NEW3,NEW4,NEW5 new
    class OLD gone
```

**Read it this way:** solid green already exists. Orange is the delta — five new units, and *nothing else*. Grey dashes are columns that exist but whose data has not been mapped yet (PRDV-16392). The dashed red node is the placeholder being retired, and retiring it is what breaks `AccessManagerOverlay.spec.ts` L186.

**The point of the diagram:** the delta is narrow and entirely additive on the backend. That is the visual case for the reclassification in report §1 — this is a wire, not a capability.

---

## Flows

**Question it answers:** where does a `null` come from, and can the reader of that `null` tell which cause produced it? (Finding F1.)

```mermaid
flowchart TD
    START["Panel needs a warning value"] --> Q1{"Column mapped by DMS?"}
    Q1 -->|"No - PRDV-16392 unshipped"| N1["value is null"]
    Q1 -->|"Yes"| Q2{"RB holds a value?"}
    Q2 -->|"No - empty or whitespace"| N2["mapper normalizes to null"]
    Q2 -->|"Yes"| VAL["string value rendered"]

    N1 --> DTO["DTO field - string or null"]
    N2 --> DTO
    DTO --> PANEL{"Panel branches on null"}
    PANEL --> COPY["renders 'No warning info'"]

    COPY --> TRUTH{"Is that statement true?"}
    TRUTH -->|"came from N2"| OK["TRUE - RB really holds nothing"]
    TRUTH -->|"came from N1"| BAD["FALSE - we simply never asked RB"]

    classDef bad fill:#f3e3e3,stroke:#b55,stroke-width:2px
    classDef ok fill:#e8f0e8,stroke:#4a7
    class BAD bad
    class OK ok
```

**Why this is the ticket's sharpest problem:** the two paths converge at `DTO` and are **indistinguishable downstream**. The panel has one branch and one string for two different truths. Until PRDV-16392 ships, every case warning and every case remark takes the left path — so the copy the request specifies asserts something false in every environment. Decision **D1** owns the fix; the structural fact that it cannot currently be told apart is settled.

---

## Sequences

**Question it answers:** does reopening the Access Manager for the same contact actually re-read RB, and which cache option is doing the work? (Finding F2.)

```mermaid
sequenceDiagram
    actor Ops as Ops user
    participant PDP as ProceedingDetailPage
    participant OV as AccessManagerOverlay
    participant CMP as useAccessManagerWarnings
    participant API as Callisto endpoint

    Note over PDP: accessManagerContact is null, v-if false, overlay not mounted

    Ops->>PDP: open Access Manager for contact 42
    PDP->>PDP: accessManagerContact = contact 42
    Note over PDP: v-if now true
    PDP->>OV: mount
    OV->>CMP: setup, enabled true
    CMP->>API: GET warnings for 42
    API-->>CMP: four values
    CMP-->>Ops: panel renders

    Ops->>OV: close
    OV->>PDP: update modelValue false
    Note over OV: transition runs
    OV->>PDP: after-leave
    PDP->>PDP: accessManagerContact = null
    Note over PDP: v-if false, overlay UNMOUNTS, composable destroyed

    Ops->>PDP: reopen the SAME contact 42
    PDP->>OV: mount again - fresh instance
    OV->>CMP: setup again
    CMP->>API: GET warnings for 42 again
    Note over CMP: refetchOnMount always fires on the fresh mount<br/>identical queryKey does not prevent it
    API-->>CMP: current values
```

**What the sequence proves:** freshness is delivered by the **unmount/remount cycle**, not by cache tuning. `refetchOnMount: 'always'` fires because the mount is genuinely new, so `staleTime: 0` is redundant. The option that earns its place is **`gcTime: 0`** — without it the cached previous response can paint for a frame before the refetch resolves, which for a *warning* means briefly showing the wrong contact's caution. `gcTime` appears nowhere else in the repo, so this is the one deliberate novelty in the composable.

**Race and timing edge cases covered by this diagram:** the `after-leave` reset is asynchronous (it waits on the transition), so a fast close-then-reopen can in principle remount before the reset lands. Worth a scenario in the test plan; the `enabled` guard (`contactId != null`) is what should absorb it.

---

## Kinds not produced

- **State diagram — N/A.** Nothing here holds multi-state lifecycle worth modelling; the panel has four independent value slots, each in one of three conditions (value / empty / failed), and the flow diagram above already captures the only branch that carries risk.
- **ER / schema diagram — N/A.** The join shape (`Contact → Firm` via `account_id`; `Proceeding → Job → Case` via `job_id` / `case_id`) is three edges and is stated in prose in report §6 and coverage-ledger area 6. A diagram would restate it without adding anything.
