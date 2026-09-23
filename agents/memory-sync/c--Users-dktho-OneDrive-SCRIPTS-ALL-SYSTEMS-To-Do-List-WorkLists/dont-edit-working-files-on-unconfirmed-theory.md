---
name: dont-edit-working-files-on-unconfirmed-theory
description: "Dustin's hard rule: confirm the diagnosis before touching a working file; and use version history, not hand-undo, to revert"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 86df1c60-3ebc-4204-a7ec-c6f8f647e83a
  modified: 2026-08-10T20:28:33.445Z
---

When something that used to work stops working, **do not modify the working file
until the cause is confirmed.** Diagnose against the live environment first.
Dustin's words: "you are changing a working example with incomplete
information," and "I want it to work the way it looks."

**Why:** on 2026-08-10 an intermittent AutoHotkey/Mouse Without Borders failure
was diagnosed wrongly twice — first as a startup-launch race, then via a stale
memory claiming the gesture couldn't cross MWB. Instrumentation and a proposed
gesture redesign were applied to a *working* file on both wrong theories. The
actual fix was **restarting Mouse Without Borders**, with zero code change. The
edits were pure waste and the revert cost more time than the diagnosis. He
raised the concern twice before I stopped, then said he'd switch tools over it.

**How to apply:**

- **Ask before editing a file that currently works.** Reading, process listing,
  and registry inspection need no permission; edits to working code do.
- **Verify the failure mode the user actually reports.** He said the script was
  running and worked locally — that ruled out "it never launched" before I
  instrumented for it. Take his direct observations as authoritative over my
  inference and over stored notes.
- **A commented-out block in his code is a deliberate decision, not a bug.**
  Don't re-enable it as a fix, don't delete it. It's kept as history.
- **Treat my own memories as stale hypotheses, not facts** — especially ones
  recorded as "pending verification." Re-verify before building a conclusion on
  one. A wrong memory is worse than none.
- **To revert, use version history** — OneDrive / OneNote / git — **not** a
  hand-reversal of individual edits. Hand-undoing many edits burns his usage
  budget and risks an imperfect restore. When there's no version history, verify
  the restore against the original **byte size**.
- **State real constraints up front, not after an hour.** If progress needs
  something only he can do (act on the other machine, rebuild the .exe), say so
  immediately. And don't invent constraints — he pushed back hard on "there is
  no constraint."
- **When he asks "can you fix it or not," answer yes or no first**, then show
  work. Hedging reads as stalling.

Related: [[mwb-ahk-constraints]], [[eng-evaluation-framework]].
