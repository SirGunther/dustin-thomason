# Diagrams — nova/nova-applies-selected-transcode-preset

> Companion to [PRDV-16398-investigation.md](./PRDV-16398-investigation.md). Each diagram states what question it answers.

## Current vs target

**Question answered:** where does the customer's selection get dropped, which parts change, and which parts are frozen? One figure — Callisto and the wire contract are off-limits by scope, so the delta must land entirely inside Nova, at exactly one hop.

```mermaid
flowchart TB
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_FROZEN["Callisto plus wire contract - FROZEN, out of scope and verified correct"]
    direction TB
    CAL1["Atlas dropdown fetched at runtime<br/>options are DB rows, not code"]
    CAL2["Gate admits only Standard and Video Mix<br/>4 of 6 values never reach Nova"]
    CAL3["Outbox event carries videoTranscodeValue as a bare string<br/>no union type - no compile-time help for Nova"]
  end

  subgraph SG_TRANSPORT["nova-orbital plus DynamoDB inbox - unchanged"]
    direction TB
    TR1["Binds queue and routing keys only<br/>never inspects the payload"]
  end

  subgraph SG_NOVA["nova-back-end - the whole delta lands here"]
    direction TB
    NOVA1["VideoJobAssembler reads the value<br/>into VideoJob.template - line 66"]
    NOVA_C1["CURRENT - TranscodeStep.apply takes 2 params<br/>no seam for a preset to arrive"]
    NOVA_C2["CURRENT - calls template1 unconditionally<br/>line 25 - the value is dropped here"]
    NOVA_T1["TARGET - rename to VideoJob.transcodeValue<br/>the old name is the vocabulary bug"]
    NOVA_T2["TARGET - apply gains a 3rd param<br/>service passes job.transcodeValue"]
    NOVA_T3["TARGET - resolveTranscodePreset returns<br/>presetValue plus buildArgs plus isFallback"]
  end

  subgraph SG_PORT["TranscoderPort - already sufficient, no change"]
    direction TB
    PORT1["transcode of input, output, args<br/>already accepts an arbitrary arg array"]
  end

  OUT_C["Standard encode returned regardless of selection<br/>wrong deliverable, silent"]
  OUT_T["The selected preset is the applied preset<br/>fallback is logged as warn, never silent"]

  CAL1 --> CAL2 --> CAL3 --> TR1 --> NOVA1
  NOVA1 --> NOVA_C1 --> NOVA_C2 --> PORT1 --> OUT_C
  NOVA1 --> NOVA_T1 --> NOVA_T2 --> NOVA_T3 --> PORT1 --> OUT_T

  class NOVA_C1,NOVA_C2,OUT_C current
  class NOVA_T1,NOVA_T2,NOVA_T3 delta
  class CAL1,CAL2,CAL3,TR1,NOVA1,PORT1 shared
  class OUT_T ok

  style SG_FROZEN    fill:#f1f3f5,stroke:#868e96,color:#212529
  style SG_TRANSPORT fill:#f3f0ff,stroke:#7048e8,color:#1f183d
  style SG_NOVA      fill:#e8f7ed,stroke:#2f9e44,color:#102015
  style SG_PORT      fill:#fff4d6,stroke:#c98a00,color:#2d2200
```

**Read it without the prose:** the selection survives Callisto, transport, and Nova's assembler intact — grey the whole way. It dies at one red hop. The port that would carry the fix already exists, so the blue chain adds no new boundary; it only fills the seam that was never opened.

## Flows

### 1. Resolution and fallback — the decision the code currently cannot make

**Question answered:** what exactly does the new resolution boundary decide, and where does the `warn` come from? This is the branch that does not exist today at all — `TranscodeStep` has no conditional of any kind.

```mermaid
flowchart TB
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015
  classDef warn    fill:#fff3bf,stroke:#f08c00,color:#3d2c00

  IN["job.transcodeValue arrives as a bare string<br/>any historical or replayed value is possible"]
  Q{"Is it a key in TRANSCODE_PRESETS"}
  HIT["isFallback false<br/>presetValue equals the requested value"]
  MISS["isFallback true<br/>presetValue falls back to Standard"]
  WARNLOG["warn - requestedValue plus appliedPreset<br/>the only channel a fallback can ever be noticed on"]
  BUILD["buildArgs of input, output"]
  LOGSTART["info on start - appliedPreset"]
  ENC["transcoder.transcode"]
  LOGEND["info on completion - appliedPreset"]

  IN --> Q
  Q -- "Standard or Video Mix" --> HIT --> BUILD
  Q -- "empty, Site Survey, template1, anything else" --> MISS --> WARNLOG --> BUILD
  BUILD --> LOGSTART --> ENC --> LOGEND

  class Q,HIT,MISS,BUILD delta
  class WARNLOG warn
  class IN shared
  class LOGEND ok
```

**The load-bearing subtlety:** the fallback branch is currently **unreachable in production** — Callisto's gate admits only the two known values. It is built anyway because the option list is data, not code (report §8, A6): a new row in `callisto.video_transcodes` becomes selectable in Atlas with no code change in any repo. Note also that `template1` sits on the *miss* branch — that is Nova's own documented local test value, and the reason the vocabulary convergence is a correctness requirement rather than tidiness.

### 2. The vocabulary mismatch — why the class was reframed

**Question answered:** what does "contract vocabulary mismatch" mean concretely, and which sites carry the wrong meaning? This is the diagram that justifies the reclassification in report §1.

```mermaid
flowchart LR
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_AUTH["Authority - Callisto owns the vocabulary"]
    direction TB
    A1["callisto.video_transcodes rows<br/>Standard and Video Mix are display labels"]
  end

  subgraph SG_WRONG["Nova - 5 sites encoding the WRONG meaning"]
    direction TB
    W1["video-job.ts line 8<br/>field named template"]
    W2["run-local-transcode.sh line 116<br/>seeds template1 - not parameterised"]
    W3["local-docker-transcode.md lines 148 and 299<br/>documents template1 as the value"]
    W4["video-job.assembler.spec.ts lines 49 and 95<br/>fixture template-1 - real labels never tested"]
    W5["payload-local.json and payload-s3.json<br/>template of template1"]
  end

  TARGET["All 5 converge on real Callisto labels<br/>acceptance criterion 7"]

  A1 -- "mirrored by none of these today" --> SG_WRONG
  W1 --> TARGET
  W2 --> TARGET
  W3 --> TARGET
  W4 --> TARGET
  W5 --> TARGET

  class W1,W2,W3,W4,W5 current
  class A1 shared
  class TARGET ok

  style SG_AUTH  fill:#fff4d6,stroke:#c98a00,color:#2d2200
  style SG_WRONG fill:#e8f7ed,stroke:#2f9e44,color:#102015
```

**Why this earns a diagram:** it is the difference between the assumed class and the confirmed one. Under "the consumer was never built," none of these five boxes exist as findings. Under "the consumer speaks the wrong vocabulary," they are the change set — and W2, W3, and W5 are the ones that would make the ticket's own verification pass against the wrong branch.

## Sequences

**N/A — there is no interleaving to expose.** Nova is a one-shot ECS/Fargate task: `onModuleInit` claims exactly one inbox event, transcodes one file, and calls `process.exit` (report §8, A8). One job per invocation, no concurrent access to shared state, no retry overlap inside the process, and no double-write window in the preset path. The inbox claim is already guarded by a conditional DynamoDB update (`claimDispatchedById`), and this change does not touch it. Recording the N/A explicitly rather than omitting the section, since "no race exists here" is itself a finding a reviewer should not have to re-derive.
