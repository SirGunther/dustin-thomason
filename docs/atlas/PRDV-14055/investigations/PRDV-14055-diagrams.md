# Diagrams — atlas/PRDV-14055

> Companion to [PRDV-14055-investigation.md](./PRDV-14055-investigation.md). Each diagram states the question it answers.

## Current vs target

What this shows: the first number's source computed changes from a "remaining" count (falls) to a "started-or-done" count (rises); the render surfaces and the second number stay frozen. Scope is **Callisto only** (LD-002); the Triton lane carries the identical defect but is **deferred to a follow-up ticket**, shown greyed.

```mermaid
flowchart TB
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_QUEUE["Upload queue - FROZEN, behavior unchanged"]
    direction TB
    Q1["uploadQueue items move prep to uploading to terminal<br/>percentCompleted 0 to 100, then isComplete"]
  end

  subgraph SG_CALLISTO["Callisto - store + title"]
    direction TB
    C_C1["CURRENT: activeUploadsCount<br/>filter not(isComplete/cancelled/error) - counts DOWN"]
    C_T1["TARGET: new display computed<br/>filter isComplete OR percentCompleted gt 0 - counts UP"]
    C_TITLE["UploadManagerTitle - active slot of<br/>'Uploading active of total files' - render unchanged"]
  end

  subgraph SG_TRITON["Triton - FOLLOW-UP ticket, NOT this scope (LD-002)"]
    direction TB
    T_C1["Triton local activeUploadsCount<br/>identical DOWN defect - LEFT AS-IS, deferred"]
    T_TITLE["UploadManagerTitle - hardcoded string<br/>count + i18n both go in the follow-up"]
  end

  OUT["First number rises to total<br/>end state first equals second equals total"]

  Q1 --> C_C1 --> C_TITLE
  Q1 --> C_T1 --> C_TITLE
  Q1 --> T_C1 --> T_TITLE
  C_T1 --> OUT

  class C_C1 current
  class C_T1 delta
  class Q1,C_TITLE,T_TITLE,T_C1 shared
  class OUT ok

  style SG_QUEUE    fill:#f1f3f5,stroke:#868e96,color:#212529
  style SG_CALLISTO fill:#e7f0ff,stroke:#3867d6,color:#10203f
  style SG_TRITON   fill:#f3f0ff,stroke:#7048e8,color:#1f183d
```

## Flows

What this shows: the per-file state progression the count keys off — which states are "not started" (excluded), "in progress" (counted), and "done" (counted).

```mermaid
flowchart LR
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  S_PREP["prepPhase parsing/starting<br/>NOT counted - not started"]
  S_WAIT["queued, waiting for slot<br/>percentCompleted 0 - NOT counted"]
  S_UP["uploading<br/>percentCompleted gt 0 - COUNTED (in progress)"]
  S_DONE["isComplete<br/>COUNTED (completed)"]
  S_ERR["error or cancelled AFTER start<br/>LD-001: stays counted, number never drops back"]

  S_PREP --> S_WAIT --> S_UP --> S_DONE
  S_UP -. failure .-> S_ERR
  S_WAIT -. start/prep failure .-> S_ERR

  class S_PREP,S_WAIT shared
  class S_UP delta
  class S_DONE ok
  class S_ERR current
```

## Sequences

What this shows: the interleaving that makes the count *rise* — a 6-file batch with concurrency 2, where at most two files transfer at once and the displayed number only increases.

```mermaid
sequenceDiagram
  participant U as User
  participant Q as Upload queue (6 files)
  participant T as Title (first number)
  U->>Q: drop 6 files
  Q->>Q: files 1,2 start (percentCompleted gt 0)
  Q-->>T: 2 of 6
  Q->>Q: file 1 completes, file 3 starts
  Q-->>T: 3 of 6
  Q->>Q: file 2 completes, file 4 starts
  Q-->>T: 4 of 6
  Q->>Q: files 3,4 complete, files 5,6 start
  Q-->>T: 6 of 6
  Q->>Q: files 5,6 complete (allUploadsComplete)
  Q-->>T: title switches to 'All files uploaded successfully'
```
