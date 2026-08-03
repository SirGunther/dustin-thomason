# Diagrams — atlas/PRDV-16402

> Companion to [PRDV-16402-investigation.md](./PRDV-16402-investigation.md). Each diagram states what question it answers.

## Current vs target

**Question answered:** which of the three file-creating paths emits a transcode request today, what exactly changes, and what must stay frozen? The eye should land on one lane — Callisto's completed-upload path — and on the fact that the *rule* is reused rather than rewritten.

```mermaid
flowchart TB
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_FRONTEND["Atlas - FROZEN, no code change"]
    direction TB
    FE1["Submitted AJSF tab - 2 upload zones<br/>both already call upload-complete-completed<br/>sends no preset - only trackTypeId and formId"]
  end

  subgraph SG_REF["The rule that already works - reference lane"]
    direction TB
    REF1["SubmitJobSubmissionFormTS<br/>preset gate plus form-scoped query<br/>3 SQL predicates - attachedToType, track Video, mime video/%"]
  end

  subgraph SG_BACKEND["Callisto - proceeding-job-submission"]
    direction TB
    B_C1["CURRENT - uploadCompleteForCompletedJobSubmission<br/>create file, audit, legacy SQS, return<br/>no outbox writer injected at all"]
    B_T1["TARGET - same 3 steps plus new TS<br/>loads form preset, reuses the gate,<br/>runs a by-fileId variant of the SAME query"]
    B_F1["FROZEN - uploadCompleteForPendingJobSubmission<br/>stays silent - submit owns batch emission"]
    B_F2["FROZEN - legacy SQS ProceedingFileUploadDispatcher<br/>behaviour unchanged, outbox is additive"]
  end

  subgraph SG_DATABASE["Callisto DB"]
    direction TB
    DB1["job_submission_forms.video_transcode_id<br/>the only per-form preset - mutable after submit,<br/>never snapshotted at submit time"]
    DB2["outbox_events<br/>id is uuidv5 over runner, ProceedingFile,<br/>fileId and files.updated_at in ms"]
  end

  subgraph SG_EXTERNAL["Nova - out of scope, and the AC gate"]
    direction TB
    EXT1["Consumes video-transcode-requested<br/>TODAY applies template1 Standard regardless<br/>PRDV-16398 fixes this and is UNSHIPPED"]
    EXT2["Emits video-transcode-completed<br/>Callisto files a derivative that already<br/>shows up indented under the original"]
  end

  FE1 --> B_C1 --> B_F2
  FE1 --> B_T1 --> B_F2
  REF1 -. same rule, new call site - not a second definition .-> B_T1
  REF1 --> DB2
  DB1 -. read by target only .-> B_T1
  B_T1 --> DB2 --> EXT1 --> EXT2

  class B_C1 current
  class B_T1 delta
  class FE1,REF1,B_F1,B_F2,DB1,DB2,EXT1 shared
  class EXT2 ok

  style SG_FRONTEND fill:#e7f0ff,stroke:#3867d6,color:#10203f
  style SG_REF      fill:#f1f3f5,stroke:#868e96,color:#212529
  style SG_BACKEND  fill:#e8f7ed,stroke:#2f9e44,color:#102015
  style SG_DATABASE fill:#fff4d6,stroke:#c98a00,color:#2d2200
  style SG_EXTERNAL fill:#f3f0ff,stroke:#7048e8,color:#1f183d
```

Read without the prose: Atlas is untouched, the eligibility rule already exists and gains a call site rather than a copy, the pending path and legacy SQS are explicitly frozen, and the green outcome sits behind a lane whose label says the companion ticket is unshipped.

## Flows

**Flow 1 — the three file-creating paths and which one emits.** Question answered: why is this a coverage gap rather than a missing feature? Three paths write AJSF proceeding files; only one emits, and one of the two silent ones is *correctly* silent.

```mermaid
flowchart LR
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  P1["POST upload-complete<br/>pending form"]
  P2["POST submit/:formId<br/>form submit"]
  P3["POST upload-complete-completed<br/>submitted form"]

  F1["Creates file plus jsffa row"]
  F2["Flips status to Done<br/>creates no file"]
  F3["Creates file plus jsffa row<br/>plus legacy SQS"]

  E1["No emit - CORRECT<br/>submit emits for these in batch"]
  E2["Emits for every eligible video<br/>on the form"]
  E3["No emit - THE DEFECT<br/>file is never requested, silently"]

  P1 --> F1 --> E1
  P2 --> F2 --> E2
  P3 --> F3 --> E3

  class E3 current
  class E2 ok
  class P1,P2,P3,F1,F2,F3,E1 shared
```

**Flow 2 — where each writer input comes from on the new path.** Question answered: what does the new transaction script actually need, and where can each value legally be read from? This is the flow that killed the coworker spec's shape — the form load must come from a repository, not from another transaction script.

```mermaid
flowchart TB
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  SVC["Completed-upload SERVICE<br/>resolves IS_VIDEO_TRANSCODE_ENABLED<br/>and passes a boolean down"]
  DTO["Request DTO<br/>has mimetype, trackTypeId, proceedingId, jobSubmissionFormId<br/>has NO preset and NO jobId"]
  USR["AuthUser identity<br/>userEmail and userFirstName"]

  TS["NEW TS<br/>may inject repositories and PORT TOKENS only"]
  BAD["FetchJobSubmissionFormTS<br/>FORBIDDEN - TS to TS is severity error"]

  R1["JobSubmissionFormRepository<br/>preset plus jobId plus jobDate"]
  R2["by-fileId variant of the outbox query<br/>the 12 projection fields incl. fileUpdatedAt"]
  GATE["IsVideoTranscodeSelectionEligibleForOutbox<br/>Standard or Video Mix only"]
  WR["Outbox writer via port token<br/>writeRequestedEvents with a 1-element files array"]

  SVC --> TS
  DTO --> SVC
  USR --> TS
  TS --> R1 --> GATE
  TS --> R2
  GATE --> WR
  R2 --> WR
  BAD -. what the coworker spec proposed - fails test:architecture .-> TS

  class BAD current
  class TS,R2 delta
  class SVC,DTO,USR,R1,GATE shared
  class WR ok
```

**Flow 3 — the round trip, and where PRDV-16398 sits.** Question answered: why can this ticket not satisfy its own acceptance criterion?

```mermaid
flowchart LR
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  A["16402 - Callisto emits<br/>videoTranscodeValue is Video Mix"]
  B["Relay publishes to nova.events"]
  C["Nova assembler puts the value on VideoJob.template"]
  D["TranscodeStep IGNORES it<br/>calls template1 Standard unconditionally"]
  E["16398 - preset registry keyed on the value<br/>UNSHIPPED - blocked on HandBrake preset"]
  F["Derivative filed and shown<br/>indented under the original"]

  A --> B --> C --> D --> F
  C --> E --> F

  class D current
  class E delta
  class A,B,C shared
  class F ok
```

The red node is what makes AC8 unverifiable today: 16402 gets the correct value all the way to Nova, and Nova throws it away.

## Sequences

**Sequence 1 — upload retry, the real duplicate-emission vector.** Question answered: why does an `existsById` guard not help? Because the retry changes `files.updated_at`, so the second event has a **different** id and no same-id guard can see it.

```mermaid
sequenceDiagram
    participant U as Videographer
    participant C as Callisto completed-upload
    participant DB as files / file_attachments / jsffa
    participant OB as outbox_events
    participant N as Nova
    U->>C: upload-complete-completed (key K)
    C->>DB: findDeletedFileByPath - withDeleted, no deletedAt filter
    Note over C,DB: name says deleted, behaviour is upsert by bucket plus filePath
    DB-->>C: no row - INSERT file id 500, updated_at T1
    C->>DB: new file_attachment plus jsffa row
    C->>OB: write event uuid5(... 500 ... T1 ...)
    C-->>U: 2xx
    U->>C: RETRY same key K (timeout, double click, flaky network)
    C->>DB: findDeletedFileByPath finds file 500
    DB-->>C: UPDATE file 500 - updated_at moves to T2
    C->>DB: ANOTHER file_attachment plus jsffa row - first is orphaned
    C->>OB: write event uuid5(... 500 ... T2 ...) - DIFFERENT id
    OB->>N: two requested events for one logical file
    Note over OB,N: existsById cannot catch this - the ids differ
```

**Sequence 2 — concurrent submit, the same-id republish window.** Question answered: what is the residual risk left by the re-submit guard, and is it introduced by this ticket? It is pre-existing — the validator runs outside the transaction — and it is the interleaving where a duplicate id *does* occur, with an UPDATE that resurrects a published row.

```mermaid
sequenceDiagram
    participant R1 as Request 1
    participant R2 as Request 2
    participant SV as JobSubmissionService
    participant TS as SubmitJobSubmissionFormTS
    participant OB as outbox_events
    R1->>SV: POST submit/:formId
    R2->>SV: POST submit/:formId
    SV->>SV: R1 status validator - form is not Done yet, passes
    SV->>SV: R2 status validator - form is STILL not Done, passes
    Note over SV: validator runs OUTSIDE the transaction - no row lock, no version column
    SV->>TS: R1 apply - transactional
    TS->>OB: write event id X for file 500
    SV->>TS: R2 apply - transactional
    TS->>OB: write event id X again - files.updated_at unchanged
    Note over OB: create() does repo.save() with an explicit PK<br/>so this UPDATEs - status back to pending, attempts back to 0
    OB->>OB: an already-published event is queued again
```

**Sequence 3 — post-submit preset edit, and why the event id cannot see it.** Question answered: what does "matching the conversion specs from the *initial* submission" actually resolve to? To the *current* value — and a changed preset is invisible to the deterministic id, because the preset is not one of its inputs.

```mermaid
sequenceDiagram
    participant V as Video-role user
    participant P as PATCH job-submission-form
    participant DB as job_submission_forms
    participant C as Completed-upload path
    participant OB as outbox_events
    Note over V,P: no guard, no ownership check, no user context, no status precondition
    V->>P: set videoTranscodeId to Video Mix on an ALREADY submitted form
    P->>DB: bare repository.update - form row only
    Note over DB: files.updated_at untouched - no cascade, no trigger, FKs are ON UPDATE NO ACTION
    V->>C: upload another video
    C->>DB: read the CURRENT preset - there is no submit-time snapshot to read
    DB-->>C: Video Mix
    C->>OB: emit with Video Mix
    Note over OB: earlier files already emitted as Standard are neither retracted nor reissued<br/>the id keys on fileId and updated_at only - the preset is not an input
```

**Sequence 4 — the happy path, for contrast.** Question answered: what does success look like end to end, once PRDV-16398 has shipped?

```mermaid
sequenceDiagram
    participant U as Videographer
    participant A as Atlas submitted tab
    participant C as Callisto
    participant OB as outbox_events
    participant N as Nova
    U->>A: drop camera-B mp4 into the proceeding upload zone
    A->>C: upload-complete-completed - no preset in the payload
    C->>C: create file, jsffa row
    C->>C: load form preset Video Mix, apply the existing gate
    C->>C: by-fileId query - 3 eligibility predicates, unchanged
    C->>OB: one event, videoTranscodeValue Video Mix
    C-->>A: 2xx - file appears in the list
    OB->>N: requested event
    N->>N: encode to Video Mix (requires PRDV-16398)
    N->>C: completed event
    C->>C: file derivative, link via file_derivations
    A-->>U: converted file renders indented under the original
```
