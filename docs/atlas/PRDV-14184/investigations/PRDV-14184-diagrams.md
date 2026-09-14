# Diagrams — atlas/PRDV-14184 (PRDV-14184)

> Companion to [PRDV-14184-investigation.md](./PRDV-14184-investigation.md). Each diagram states what question it answers.

## Current vs target

Answers: *why does the same one-line fix work on one create surface and silently fail on the other, and where does the change actually land?* The two surfaces share the same repeater shape but differ in **how their container is hidden** — that difference, not the input, is the whole design constraint.

```mermaid
flowchart TB
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_FROZEN["callisto-back-end - FROZEN, nothing to change"]
    direction TB
    BE1["Proceeding.value - required varchar, no default<br/>both create DTOs require client-supplied names<br/>name is typed before any request exists"]
  end

  subgraph SG_S1["Surface 1 - NewProceedingsOverlay - Job Detail"]
    direction TB
    S1_SHARED["Container - Overlay hides with v-show<br/>mounted unconditionally by AddNewProceeding<br/>input mounts ONCE at page load, while hidden"]
    S1_C["CURRENT: q-input has no ref, no autofocus<br/>user must click into the box"]
    S1_NAIVE["REJECTED: plain autofocus attribute<br/>fires once at page load into a hidden field<br/>never fires again on open"]
    S1_T["TARGET: watch modelValue plus append handler<br/>call QInput.focus on the collected row ref"]
  end

  subgraph SG_S2["Surface 2 - AddProceedingForm - Job Submission"]
    direction TB
    S2_SHARED["Container - q-card behind v-if showAddForm<br/>mounts fresh on every reveal"]
    S2_C["CURRENT: q-input has no ref, no autofocus<br/>user must click into the box"]
    S2_T["TARGET: same two hooks - reveal plus append<br/>call QInput.focus on the collected row ref"]
  end

  subgraph SG_REF["Idioms the repo already has"]
    direction TB
    R1["ref plus .focus deferred - SearchBar<br/>callback refs per v-for row - CaseFilesTable"]
  end

  OUT["Cursor is already in the empty name box<br/>on create AND on each added row, both surfaces"]

  BE1 -. name never crosses the boundary before typing .-> S1_SHARED
  S1_SHARED --> S1_C
  S1_SHARED --> S1_NAIVE
  S1_SHARED --> S1_T
  S2_SHARED --> S2_C
  S2_SHARED --> S2_T
  R1 -. same idiom, new call sites .-> S1_T
  R1 -. same idiom, new call sites .-> S2_T
  S1_T --> OUT
  S2_T --> OUT

  class S1_C,S2_C,S1_NAIVE current
  class S1_T,S2_T delta
  class BE1,S1_SHARED,S2_SHARED,R1 shared
  class OUT ok

  style SG_FROZEN fill:#f1f3f5,stroke:#868e96,color:#212529
  style SG_S1     fill:#e7f0ff,stroke:#3867d6,color:#10203f
  style SG_S2     fill:#e7f0ff,stroke:#3867d6,color:#10203f
  style SG_REF    fill:#f1f3f5,stroke:#868e96,color:#212529
```

Read without the prose: the backend is untouched, both surfaces need the same change, the repo already owns the idiom — and the rejected shortcut is drawn in red **inside Surface 1's lane** so it is visible exactly where it would have been applied.

## Flows

Answers: *which code events are the two acceptance criteria, on each surface?* This is the picture that turns "AC-1 and AC-2" into four concrete hook points.

```mermaid
flowchart LR
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  U1["User clicks New Proceeding<br/>showNewProceedingsOverlay = true"]
  U2["User clicks Add Proceeding<br/>showAddForm = true"]
  U3["User clicks Add another proceeding"]

  H1["AC-1 hook - container became visible<br/>S1 watch modelValue · S2 v-if reveal"]
  H2["AC-2 hook - row appended<br/>addProceeding / addProceedingField push empty string"]

  ROW0["Row 0 exists from ref with one empty string"]
  ROWN["New empty row at the end of the array"]

  F["Deferred focus on that row's QInput<br/>nextTick, or setTimeout if the transition needs it"]
  OUT["User types immediately - no click"]

  U1 --> H1
  U2 --> H1
  U3 --> H2
  H1 --> ROW0 --> F
  H2 --> ROWN --> F
  F --> OUT

  class H1,H2,F delta
  class U1,U2,U3,ROW0,ROWN shared
  class OUT ok
```

Note the asymmetry the diagram makes concrete: **two user actions map to AC-1** (one per surface) and they are *different mechanisms*, while AC-2 is the same `push('')` shape on both.

## Sequences

Answers: *is there an interleaving where focus lands on the wrong element, or on a detached one?* Not a race between actors — a single-user ordering problem between Vue's DOM update, `v-show`, and the CSS transition. This is the timing question recorded as assumption A5, and the reason the change is not considered proven by unit tests alone.

```mermaid
sequenceDiagram
    participant U as Ops user
    participant V as Vue reactivity
    participant D as DOM
    participant T as CSS Transition
    U->>V: click New Proceeding - modelValue true
    V->>D: patch - v-show clears display none
    V->>T: enter transition begins - opacity and transform
    Note over D,T: element is in the DOM and displayed,<br/>but still mid-animation
    V-->>U: nextTick fires here
    alt focus at nextTick succeeds
        U->>D: focus lands on row 0 input
    else element not yet focusable
        Note over U,D: focus call is a silent no-op<br/>user types into nowhere
        U->>D: setTimeout defers past the frame - focus lands
    end
```

The failure mode on the right-hand branch is **silent** — `HTMLElement.focus()` on a non-focusable element throws nothing. That is precisely why A5 must be settled by browser observation rather than by a green assertion, and why any `setTimeout` that ships must carry a comment naming the timing constraint it exists for rather than standing as an unexplained delay.

A second interleaving worth stating, which needs no diagram: **remove a row, then add one.** `removeProceeding` splices the array while rows are keyed by index, so a per-row ref map can retain an entry pointing at a detached element. Covered as a negative path in report §9 rather than drawn, because the ordering is linear and prose carries it without loss.
