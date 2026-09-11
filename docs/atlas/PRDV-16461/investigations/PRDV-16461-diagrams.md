# Diagrams — atlas/PRDV-16461

> Companion to [PRDV-16461-investigation.md](./PRDV-16461-investigation.md). Each diagram states what question it answers.

## Current vs target

**Question answered:** where does a collection default come from today, why does it never appear for Transcript or Video, and which parts change versus stay frozen?

```mermaid
flowchart TB
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_ENTRY["Entry paths (atlas-front-end)"]
    E_DND["Generic drag-and-drop<br/>lockedTrackTypeId = null"]:::shared
    E_DIRECT["Direct per-track upload<br/>lockedTrackTypeId set"]:::shared
    E_APPROVE["File approval<br/>track from first file"]:::shared
    E_RECAT["Recategorize<br/>existing collection passed"]:::shared
    E_TRACKSEL["NEW - explicit track selection<br/>permitted tracks only"]:::delta
  end

  subgraph SG_RESOLVER["Initial-selection resolver (useDeliverableFileUploadForm)"]
    R_ENTRY["resolveInitialPickValue()"]:::shared
    R_NOTRACK["no track - return null<br/>line 387-388"]:::current
    R_EXISTING["existing collection matches - use it<br/>line 390-406"]:::shared
    R_SINGLETON["exactly one static pick - use it<br/>line 407-414"]:::current
    R_MAPPED["NEW - track is mapped<br/>select that exact static value"]:::delta
    R_BLANK["NEW - mapped but absent<br/>return null, do NOT fall through"]:::delta
    R_GUARD["NEW - recategorize guard<br/>covers mapping AND singleton"]:::delta
  end

  subgraph SG_DATA["Collection catalog (already on the wire)"]
    D_API["GET /granting-client-access/deliverable-collections"]:::shared
    D_SHAPE["staticCollections[].value + eligibleTypes"]:::shared
  end

  subgraph SG_FROZEN["Frozen - must not change"]
    F_BACKEND["Callisto - no change<br/>no new endpoint, no DTM config"]:::shared
    F_SENTINEL["t-id-none sentinel<br/>Exhibits and MVC keep auto-select"]:::shared
    F_DYNAMIC["Dynamic picks never auto-selected"]:::shared
    F_BATCH["Batch, validation, mixed-track rules"]:::shared
  end

  OUT_TODAY["Today - user picks the collection by hand"]:::current
  OUT_TARGET["Target - collection already correct"]:::ok

  D_API --> D_SHAPE --> R_ENTRY

  E_DND -->|current| R_ENTRY
  E_DIRECT --> R_ENTRY
  E_APPROVE --> R_ENTRY
  E_RECAT --> R_ENTRY

  R_ENTRY --> R_NOTRACK --> OUT_TODAY
  R_ENTRY --> R_EXISTING
  R_ENTRY --> R_SINGLETON -->|"count is 2 for Transcript and Video"| OUT_TODAY

  E_DND -.->|target| E_TRACKSEL
  E_TRACKSEL --> R_ENTRY
  R_ENTRY --> R_GUARD --> R_MAPPED --> OUT_TARGET
  R_MAPPED -.->|value absent| R_BLANK --> OUT_TODAY

  R_GUARD -.->|preserves| F_SENTINEL
  R_MAPPED -.->|never| F_DYNAMIC

  style SG_ENTRY fill:#e7f0ff,stroke:#3867d6,color:#10203f
  style SG_RESOLVER fill:#e7f0ff,stroke:#3867d6,color:#10203f
  style SG_DATA fill:#fff4d6,stroke:#c98a00,color:#2d2200
  style SG_FROZEN fill:#f1f3f5,stroke:#868e96,color:#212529
```

**What to read from it.** The red chain is today: a track with two static collections fails the `matches.length === 1` test and falls out to a manual pick. Generic drag-and-drop fails even earlier, at the no-track return. The blue nodes are the change — a track-selection state for drag-and-drop, a mapped lookup ahead of the singleton rule, an explicit blank on a missing mapped value, and a guard that covers both the new mapping and the pre-existing singleton rule. Everything grey is untouched, including the whole backend and the collectionless-track sentinel that Exhibits and MVC depend on.

## Flows

**Question answered:** in the current combined picker, what is actually selectable — and why is "select a track" not an event the code can observe?

```mermaid
flowchart LR
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529

  subgraph SG_TODAY["Today - one combined q-select"]
    T_HDR1["Transcript (groupHeader)<br/>disable = true"]:::current
    T_C1["Full Transcript (pick)"]:::shared
    T_C2["Redacted (pick)"]:::shared
    T_DYN1["Excerpt (dynamic pick)"]:::shared
    T_HDR2["Video (groupHeader)<br/>disable = true"]:::current
    T_C3["MP4 Video (pick)"]:::shared
    T_C4["MPEG Video (pick)"]:::shared
  end

  subgraph SG_TARGET["Target - two controls"]
    N_TRACK["Track control<br/>permitted tracks only"]:::delta
    N_COLL["Collection control<br/>scoped to chosen track"]:::delta
  end

  T_HDR1 -.->|"not clickable - no track event"| T_C1
  T_HDR2 -.->|"not clickable - no track event"| T_C3

  T_C1 --> T_BOTH["one click sets BOTH<br/>track and collection"]:::current
  T_C3 --> T_BOTH

  N_TRACK -->|"emits an observable track change"| N_COLL
  N_COLL --> N_SPLIT["two steps - the track change<br/>is something code can watch"]:::delta

  T_BOTH -.->|"replaced by"| N_TRACK
```

**What to read from it.** Track headings exist visually but carry `disable: true`, so the only selectable rows are individual collections. Choosing one sets track and collection in the same act, which is why there is no "user selected a track" moment for a default to react to. The target splits that into two steps so the track change becomes observable.

## Sequences

**Question answered:** what is the ordering hazard when the user changes the track after the collections query has already resolved and they have made a manual override?

```mermaid
sequenceDiagram
    participant U as User
    participant F as Upload form
    participant R as resolveInitialPickValue
    participant Q as Deliverable-types query

    U->>F: choose track Transcript
    F->>R: resolve for Transcript
    R-->>F: Full Transcript (mapped default)
    F->>Q: fetch eligible types for Full Transcript
    Q-->>F: catalog, per-file types pre-fill

    Note over U,F: user deliberately overrides
    U->>F: change collection to Redacted
    F->>Q: refetch for Redacted
    Q-->>F: catalog, types re-evaluate

    Note over U,F: async options backfill must NOT fire here
    F->>F: backfill guard - selectedPickValue is not null, skip

    U->>F: change track to Video
    F->>F: clear collection, dynamic state, per-file types
    F->>R: resolve for Video
    R-->>F: MP4 Video (mapped default)
    Note right of F: the Redacted override is discarded<br/>a track change is a reset, not an override to protect
    F->>Q: fetch eligible types for MP4 Video
```

**What to read from it.** Two guards sit in tension and the order matters. The existing async backfill must never overwrite a deliberate choice, so it checks that nothing is selected before acting. But a **track change** must overwrite that same choice, because the override belonged to the previous track. The spec states this explicitly: preserve an override only while the track is unchanged.

**Race conditions:** N/A — this is single-user, single-tab, client-side state. There is no concurrent writer, no shared mutable server state on this path, and no retry window. The only interleaving that matters is the local one drawn above.
